# ranked-model-hstore

Что ожидаем:

1. Возможность применять concern для других моделей (не только product)
2. Возможность указывать название поля для сортировки (`category_positions`) и scope-поля (`by_category_id`)
3. Минимум SQL запросов при сохранении.
4. Колбеки при пересортировке.
5. Если товар добавляется в категорию у него автоматически должен появиться порядок.
6. Защита от случаев когда у товаров нет значения сортировки (в этом случае они должны появиться)
