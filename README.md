---

# Integration Project: CMS → PostgreSQL → Report API

Этот проект реализует интеграционное приложение, выполняющее двунаправленную синхронизацию данных между внешней CMS, локальной базой данных PostgreSQL и Report API. Приложение разработано на базе n8n.

## 1. Назначение проекта

Приложение решает две задачи:

### Поток данных №1: CMS → PostgreSQL

1. Получение данных о запасных частях из CMS по API.
2. Обработка пагинации (минимальная реализация для совместимости с заданием).
3. Сохранение данных в PostgreSQL:

   * новые записи добавляются;
   * существующие обновляются;
   * поле `last_seen_at` фиксирует время последнего появления записи в CMS.

### Поток данных №2: PostgreSQL → CSV → Report API

1. Формирование CSV-файла на основе данных из PostgreSQL.
2. CSV формируется строго в формате:

   ```
   spareCode;spareName;spareDescription;spareType;spareStatus;price;quantity;updatedAt
   ```
3. Кодировка CSV: UTF-8
4. Разделитель: точка с запятой `;`
5. Полученный CSV отправляется в Report API по HTTP POST.
6. API возвращает результат синхронизации, который используется для контроля корректности данных.

---

## 2. Используемые технологии

* n8n (cloud)
* PostgreSQL 18
* HTTP API CMS
* Report API
* Node.js runtime внутри нод n8n (JavaScript Code nodes)

---

## 3. Структура репозитория

```
.
├── README.md        — описание проекта
├── integration.json — экспортированный workflow n8n
└── schema.sql       — SQL-схема таблицы historical_spares
```

---

## 4. Структура базы данных

SQL-схема (файл `schema.sql`):

```sql
CREATE TABLE IF NOT EXISTS historical_spares (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL,
  spare_code TEXT NOT NULL,
  spare_name TEXT,
  spare_description TEXT,
  spare_type TEXT,
  spare_status TEXT,
  price NUMERIC(12,2),
  quantity INTEGER,
  updated_at TIMESTAMP WITH TIME ZONE,
  inserted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT uq_student_spare UNIQUE (student_id, spare_code)
);
```

Описание назначений ключевых полей:

* `student_id` — идентификатор студента по заданию
* `spare_code` — уникальный код детали
* `updated_at` — значение из CMS
* `inserted_at` — время первой записи в БД
* `last_seen_at` — время, когда запись последний раз появилась в CMS
* `uq_student_spare` — уникальность пары (student_id, spare_code)

---

## 5. Основной workflow (integration.json)

Workflow выполняет:

### 1. Получение данных из CMS

* Инициализация первой страницы
* Пошаговый вызов API CMS
* Объединение всех страниц в один массив

### 2. Запись в PostgreSQL

* Каждая запись вставляется или обновляется через
  `INSERT ... ON CONFLICT DO UPDATE`
* Обновляется `last_seen_at`, чтобы избежать устаревших записей

### 3. Получение данных из БД

* Выборка всех записей студента из таблицы `historical_spares`

### 4. Формирование CSV

* Формирование текста CSV, где каждая строка — одна запись из БД
* Корректное экранирование и разделители `;`

### 5. Отправка CSV в Report API

* HTTP POST
* Content-Type: `text/csv; charset=utf-8`
* Тело запроса — чистый текст CSV

---

## 6. Инструкция по запуску

1. Создать базу данных PostgreSQL.

2. Выполнить SQL из `schema.sql`.

3. Импортировать `integration.json` в n8n.

4. Настроить в нодах:

   * параметры подключения к PostgreSQL,
   * studentId (в данном проекте использовался studentId = 13),
   * URL CMS,
   * URL Report API.

5. Запустить workflow вручную или по расписанию.

---

## 7. Результат работы

Report API возвращает структуру вида:

```json
{
  "studentId": 13,
  "result": 5,
  "lastSyncAt": "2025-11-30T06:36:05Z",
  "lastSyncMessage": "CSV содержит записей – 50. Кол-во деталей не найденных в CSV – 0, Кол-во деталей с неточными данными – 0. Кол-во ожидаемых записей – 50"
}
```

Поле `result` показывает статус интеграции.

---


