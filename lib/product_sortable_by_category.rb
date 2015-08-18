require 'active_support'

module ProductSortableByCategory
  extend ActiveSupport::Concern

  included do
    scope :ordered_by_category, lambda { |category_id|
      by_category_id(category_id)
        .order ActiveRecord::Base.send(:sanitize_sql_array,
                                       ['(products.category_positions -> ?)::integer asc', category_id.to_s])
    }

    scope :by_category_position, lambda { |category_id, pos|
      where ActiveRecord::Base.send(:sanitize_sql_array,
                                    ['products.category_positions -> ? = ? ', category_id.to_s, pos.to_s])
    }

    scope :without_category_position, lambda { |category_id|
      where 'not exist(products.category_positions, ?)', category_id.to_s
    }

    before_save :handle_categories_ranking
  end

  def self.arrange_products_in_category(category_id)
    scope = Product
      .alive
      .by_category_id(category_id)
      .without_category_position(category_id)

    count = scope.count
    return unless count > 0

    last = Product
      .alive
      .by_category_id(category_id)
      .ordered_by_category(category_id)
      .last

    last_position = last.position_in_category category_id if last.present?
    last_position ||= 0
    step = ((RankedModel::MAX_RANK_VALUE.to_f - last_position) / count).ceil
    step = 1 if step < 1

    scope.each_with_index do |p, index|
      p.rank_category_position_at category_id, last_position + (index + 1) * step
      p.update_column :category_positions, p.category_positions
      p.reindex
    end
  end

  # @param position - порядковый номер элемента в категории, начиная с 0
  def update_position_in_category!(category_id, position)
    update_position_in_category category_id, position
    save!
  end

  # @param position - порядковый номер элемента в категории, начиная с 0
  #
  def update_position_in_category(category_id, position)
    case position
    when :last
      last = self.class.ordered_by_category(category_id).last

      if last.present?
        rank = last.ranked_position_in_category(category_id).to_i
        rank = ((RankedModel::MAX_RANK_VALUE - rank).to_f / 2).ceil + rank

        rank_category_position_at category_id, rank
      else
        update_position_in_category category_id, :middle
      end

    when :middle
      update_position_in_category(
        category_id,
        ((RankedModel::MAX_RANK_VALUE - RankedModel::MIN_RANK_VALUE).to_f / 2).ceil +
        RankedModel::MIN_RANK_VALUE
      )
    when Integer
      fail 'Position must starts from 0' if position < 0
      neighbors = neighbors_at_position(category_id, position)
      min = neighbors[:lower] ? neighbors[:lower].ranked_position_in_category(category_id) : RankedModel::MIN_RANK_VALUE
      max = neighbors[:upper] ? neighbors[:upper].ranked_position_in_category(category_id) : RankedModel::MAX_RANK_VALUE

      min ||= RankedModel::MIN_RANK_VALUE
      max ||= RankedModel::MAX_RANK_VALUE

      ranked_position = ((max - min).to_f / 2).ceil + min
      rank_category_position_at category_id, ranked_position
    when NilClass
      update_position_in_category category_id, :last
    when String
      update_position_in_category category_id, position.to_i
    else
      fail "Unknown type of position #{position}"
    end
  end

  def ranked_position_in_category(category_id)
    val = category_positions[category_id.to_s]
    val ? val.to_i : nil
  end

  def position_in_category(category_id)
    over  = "order by (category_positions->'#{category_id}')::integer asc"
    where = "#{category_id} = ANY(categories_ids) and deleted_at is null"
    res = self.class.connection
      .execute("SELECT id, row_number() over(#{over}) from products where #{where}")
      .find { |a| a['id'] == id.to_s }
    return nil unless res
    res['row_number'].to_i - 1
  end

  def rank_category_position_at(category_id, ranked_position)
    fail "must be a Fixnum #{ranked_position}" unless ranked_position.is_a? Fixnum
    self.category_positions = category_positions.merge category_id.to_s => ranked_position

    # Determine if a record was created or destroyed in a transaction. State should be one of :new_record or :destroyed.
    # transaction_record_state
    #  :create, :update, or :destroy
    # transaction_include_any_action?
  end

  private

  def current_category_position_at_rank(category_id, position)
    scope = self.class
      .alive
      .by_category_id(category_id)
      .by_category_position(category_id, position)

    scope = scope.where.not(id: id) if persisted?

    scope.first
  end

  def rearrange_ranks_if_need(category_id)
    ranked_position = ranked_position_in_category category_id
    if ranked_position.present? &&
        (ranked_position > RankedModel::MAX_RANK_VALUE ||
        current_category_position_at_rank(category_id, ranked_position))
      rearrange_ranks category_id
    end
  end

  def handle_categories_ranking
    unless new_record?
      if changed_categories_ids.any?
        changed_categories_ids.each do |cid|
          rearrange_ranks_if_need cid
        end
      end
    end
    categories_ids.each do |cid|
      if ranked_position_in_category(cid)
        rearrange_ranks_if_need cid
      else
        update_position_in_category cid, :last
      end
    end
  end

  def changed_categories_ids
    a = Set.new Array(categories_ids)
    b = Set.new Array(categories_ids_was)
    ids = (a + b) - (a & b)

    ids += (category_positions.keys + category_positions_was.keys)
      .uniq
      .reject { |key| category_positions[key].to_s == category_positions_was[key].to_s }
      .compact
      .map { |id| id.to_s.to_i }

    ids.sort
  end

  def rearrange_ranks(category_id, arrange_blank = true)
    scope = self.class.alive.ordered_by_category category_id
    scope = scope.where.not(id: id) if persisted?
    position = ranked_position_in_category category_id

    scope = scope
      .where('(category_positions -> ?)::integer >= ? ', category_id.to_s, position)

    scope
      .update_all "category_positions = hstore('#{category_id}', ((category_positions -> '#{category_id}')::integer + 1)::text)"

    ProductSortableByCategory.arrange_products_in_category category_id if arrange_blank

    Chewy::Strategy::Sidekiq::Worker.perform_async GoodsIndex::Product.name, scope.pluck(:id)
  end

  def neighbors_at_position(category_id, pos)
    finder = self.class.alive.ordered_by_category(category_id).where.not(id: id)
    finder_lower = pos <= 0 ? nil : finder.offset(pos - 1).first
    finder_upper = finder.offset(pos).first

    {
      lower: finder_lower,
      upper: finder_upper
    }
  end
end
