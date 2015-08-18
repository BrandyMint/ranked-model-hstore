# ranked-model-hstore

## Что это такое?

Это вытяжка concern-а отвечающего за сортирову товаров в различных категориях через позицию в hstore применяемыую в проекте http://kiiiosk.ru/

За основу был взят код из модуля (https://github.com/mixonic/ranked-model)[ranked-model]

## Что с этим не так?

1. Плохой код, не используемый повторно.
2. Многие процедуы не оптимизированы.
3. Путаница в терминах.

## Что ожидаем

1. Возможность применять concern для других моделей (не только product), указывать название поля для сортировки (`category_positions`) и scope-поля (`by_category_id`), в общем сделать модуль которым можно пользоваться и в других проектах.
3. Минимум SQL запросов при сохранении.
4. Колбеки при пересортировке (например у нас все товары отражаются в elasticsearch и при массовом изменении позиции необходимо также массово обновлять товары в elastic).
5. Если товар добавляется в категорию у него автоматически должен появиться порядок. Бывает так, что товар в категорию добавили, но позицию не установили, в итоге это ломает сортировку.
6. Защита от случаев когда у товаров нет значения сортировки (в этом случае они должны появиться), см предыдующий пункт.
7. Возможность узнать порядковое значение товара.
8. Тесты перевести на minitest.

## Условия

* Используем SOLID, делим код на объекты.

## С чего начать?

* Для начала нужно настроить окружение и запустить те тесты что уже есть. Они должны проходить.
* Разбить задачу на несколько этапов, описать порядок разработки и сроки.

## Термины

* rank - порядковое значение товара (0,1,2,3,4)
* position - raw-значение позиции в списке (-10000, -5000, 0, 5000, 10000)


См пример: 
