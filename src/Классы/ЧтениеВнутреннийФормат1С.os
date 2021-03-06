///////////////////////////////////////////////////////////////////
//
// Чтение файлов во внутреннем формате 1с
// За основу взята разработка https://github.com/arkuznetsov/yabr
// (с) BIA Technologies, LLC	
//
///////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////
// Программный интерфейс
///////////////////////////////////////////////////////////////////

// Выполняет чтение файла во внутреннем формате 1с(скобочном)
//
// Параметры:
//  ПутьКФайлу                 - Строка       -  путь к файлу для чтения
//  НачальнаяСтрока            - Число        -  номер начальной строки файла для чтения
//
//  Возвращаемое значение:
//  Структура    - Новый элемент
//		*Родитель    - Структура            - ссылка на элемент-родитель
//		*Уровень     - Число                - уровень иерархии элемента
//		*Индекс      - Число                - индекс элемента в массиве значений родителя
//		*НачСтрока   - Число                - номер первой строки из которой был прочитан элемент и его дочерние элементы
//		*КонСтрока   - Число                - номер последней строки из которой был прочитан элемент и его дочерние элементы
//		*Значения    - Массив(Структура)    - массив дочерних элементов
//
Функция ПрочитатьФайл(ПутьКФайлу, НачальнаяСтрока = 1) Экспорт
	
	СтруктураЧтения = ИнициализироватьЭлемент(Неопределено);
	
	Текст = Новый ЧтениеТекста(ПутьКФайлу, КодировкаТекста.UTF8NoBOM);
	
	ДанныеСтроки = Текст.ПрочитатьСтроку();
	
	Начало = ТекущаяУниверсальнаяДатаВМиллисекундах();
	ТекНачало = Начало;
	НачКоличество = 0;
	
	НомерСтроки = 1;
	
	Пока НЕ ДанныеСтроки = Неопределено Цикл
		
		Если НомерСтроки < НачальнаяСтрока И НЕ НачальнаяСтрока < 1 Тогда
			ДанныеСтроки = Текст.ПрочитатьСтроку();
			НомерСтроки = НомерСтроки + 1;
			Продолжить;
		КонецЕсли;
		
		СтрокаДляОбработки = "";
		СтрокаДляОбработкиПрочитана = Ложь;
		КавычкиОткрыты = Ложь;
		
		// сборка "завершенной" строки, где кавычки закрыты и последний символ = "," или "}"
		Пока НЕ (СтрокаДляОбработкиПрочитана ИЛИ ДанныеСтроки = Неопределено) Цикл
			
			СтрокаДляОбработкиПрочитана = ДополнитьСтрокуДляОбработки(СтрокаДляОбработки, ДанныеСтроки, КавычкиОткрыты);
			
			Если НЕ СтрокаДляОбработкиПрочитана Тогда
				
				Если КавычкиОткрыты Тогда
					СтрокаДляОбработки = СтрокаДляОбработки + Символы.ПС;
				КонецЕсли;

				ДанныеСтроки = Текст.ПрочитатьСтроку();
				НомерСтроки = НомерСтроки + 1;

			КонецЕсли;

		КонецЦикла;
		
		СчетчикСимволов = 1;
		
		ПрочитатьДанныеСтроки(СтруктураЧтения, СтрокаДляОбработки, СчетчикСимволов);
				
		ДанныеСтроки = Текст.ПрочитатьСтроку();
		
		НомерСтроки = НомерСтроки + 1;
		
	КонецЦикла;
	
	Текст.Закрыть();

	Если НЕ ПустаяСтрока(СтрокаДляОбработки) Тогда
		ПрочитатьДанныеСтроки(СтруктураЧтения, СтрокаДляОбработки, СчетчикСимволов);
	КонецЕсли;
	
	НачальнаяСтрока = НомерСтроки;
	
	// переход к корневому элементу структуры чтения
	Пока НЕ СтруктураЧтения.Родитель = Неопределено Цикл
		СтруктураЧтения = СтруктураЧтения.Родитель;
	КонецЦикла;
	
	Результат = СтруктураЧтения;
	
	Возврат Результат;
	
КонецФункции // ПрочитатьФайл()

///////////////////////////////////////////////////////////////////
// Служебный функционал
///////////////////////////////////////////////////////////////////

// Функция - добавляет строку к исходной и возвращает признак завершенности строки
// исходя из закрытия кавычек и окончания строки на "," или "}" 
//
// Параметры:
//  ДополняемаяСтрока    - Строка - исходная строка
//  Дополнение           - Строка - добавляемая строка
//  КавычкиОткрыты       - Булево - Истина - кавычки открыты; Ложь - кавычки закрыты
// 
// Возвращаемое значение:
//  Булево - Истина - строка завершена; Ложь - строка не завершена
//
Функция ДополнитьСтрокуДляОбработки(ДополняемаяСтрока, Дополнение, КавычкиОткрыты)
	
	КоличествоКавычек = СтрЧислоВхождений(Дополнение, """");
	
	Если КавычкиОткрыты Тогда
		КавычкиОткрыты = (КоличествоКавычек % 2 = 0);
	Иначе
		КавычкиОткрыты = (КоличествоКавычек % 2 = 1);
	КонецЕсли;
	
	ДополняемаяСтрока = ДополняемаяСтрока + Дополнение;
	
	ПоследнийСимвол = Сред(Дополнение, СтрДлина(Дополнение), 1);
	
	// строка завершена если кавычки закрыты и последний символ = "," или "}"
	Возврат (НЕ КавычкиОткрыты) И (ПоследнийСимвол = "}" ИЛИ ПоследнийСимвол = ",");
	
КонецФункции // ДополнитьСтрокуДляОбработки()

// Функция - создает структуру нового элемента
//
// Параметры:
//  Родитель     - Структура              - ссылка на элемент-родитель (для корневого элемента "Неопределено")
// 
// Возвращаемое значение:
//  Структура    - Новый элемент
//		*Родитель    - Структура            - ссылка на элемент-родитель
//		*Уровень     - Число                - уровень иерархии элемента
//		*Индекс      - Число                - индекс элемента в массиве значений родителя
//		*НачСтрока   - Число                - номер первой строки из которой был прочитан элемент и его дочерние элементы
//		*КонСтрока   - Число                - номер последней строки из которой был прочитан элемент и его дочерние элементы
//		*Значения    - Массив(Структура)    - массив дочерних элементов
//
Функция ИнициализироватьЭлемент(Знач Родитель)
	
	Уровень = 0;
	Если ТипЗнч(Родитель) = Тип("Структура") Тогда
		Если Родитель.Свойство("Уровень") Тогда
			Уровень = Родитель.Уровень + 1;
		КонецЕсли;
	КонецЕсли;
	
	Индекс = 0;
	Если ТипЗнч(Родитель) = Тип("Структура") Тогда
		Если Родитель.Свойство("Значения") Тогда
			Индекс = Родитель.Значения.ВГраница() + 1;
		КонецЕсли;
	КонецЕсли;
	
	Результат = Новый Структура("Родитель,
	                            |Уровень,
	                            |Индекс,
	                            |НачСтрока,
	                            |КонСтрока,
	                            |Значения",
	                            Родитель,
	                            Уровень,
	                            Индекс,
								0,
								0,
	                            Новый Массив());
	
	
	Возврат Результат;
	
КонецФункции // ИнициализироватьЭлемент()

// Процедура - Читает, разбирает данные из переданной строки и добавляет результат в иерархию массива структур
//
// Параметры:
//  ЭлементДляЗаполнения     - Структура                 - структура элемента
//		*Родитель            - Структура                 - ссылка на элемент-родитель
//		*Уровень             - Число                     - уровень иерархии элемента
//		*Индекс              - Число                     - индекс элемента в массиве значений родителя
//		*НачСтрока           - Число                     - номер первой строки из которой был прочитан элемент и его дочерние элементы
//		*КонСтрока           - Число                     - номер последней строки из которой был прочитан элемент и его дочерние элементы
//		*Значения            - Массив(Структура)         - массив дочерних элементов
//  ДанныеСтроки             - Строка                    - строка для разбора
//  СчетчикСимволов          - Число                     - счетчик прочитанных символов переданной строки
//
Процедура ПрочитатьДанныеСтроки(ЭлементДляЗаполнения, ДанныеСтроки, СчетчикСимволов)

	ТекСтрока = "";
	КавычкиОткрыты = Ложь;
	ПредСимвол = "";
	
	ДлинаСтроки = СтрДлина(ДанныеСтроки);
	
	// посимвольное чтение строки
	Для НомерСимвола = СчетчикСимволов По ДлинаСтроки Цикл
		
		ТекСимвол = Сред(ДанныеСтроки, НомерСимвола, 1);
		
		Если КавычкиОткрыты Тогда // обработка строки внутри кавычек

			Если ТекСимвол = """" Тогда
				
				Если Сред(ДанныеСтроки, НомерСимвола, 2) = """""" Тогда  // это экранированные кавычки внутри строки
					
					ТекСтрока = ТекСтрока + Сред(ДанныеСтроки, НомерСимвола, 2);
					НомерСимвола = НомерСимвола + 1;

				Иначе // закрытие кавычек
					
					ТекСтрока = ТекСтрока + ТекСимвол;
					КавычкиОткрыты = Ложь;

				КонецЕсли;
				
			Иначе // любой символ добавляется к строке
				
				ТекСтрока = ТекСтрока + ТекСимвол;
				
			КонецЕсли;

		ИначеЕсли ТекСимвол = """" Тогда // открытие кавычек
			
			ТекСтрока = ТекСтрока + ТекСимвол;
			КавычкиОткрыты = Истина;

		ИначеЕсли ТекСимвол = "{" Тогда // открытие вложенного списка
			
			Если ЭлементДляЗаполнения = Неопределено Тогда

				ВремЭлементДляЗаполнения = ИнициализироватьЭлемент(Неопределено);
				ЭлементДляЗаполнения = ВремЭлементДляЗаполнения;

			Иначе
				
				ВремЭлементДляЗаполнения = ИнициализироватьЭлемент(ЭлементДляЗаполнения);
				ЭлементДляЗаполнения.Значения.Добавить(ВремЭлементДляЗаполнения);
				
			КонецЕсли;
			
			НомерСимвола = НомерСимвола + 1;
			
			ПрочитатьДанныеСтроки(ВремЭлементДляЗаполнения, ДанныеСтроки, НомерСимвола);

			Если НомерСимвола > СтрДлина(ДанныеСтроки) Тогда
				
				ЭлементДляЗаполнения = ВремЭлементДляЗаполнения; // если строка закончилась, то "наверх" поднимается элемент текущего уровня
				Возврат;
				
			КонецЕсли;
			
		ИначеЕсли ТекСимвол = "}" Тогда // закрытие вложенного списка
			
			Если НЕ (ПредСимвол = "{" ИЛИ ПредСимвол = "}" ИЛИ ПредСимвол = "") Тогда
				
				ЭлементДляЗаполнения.Значения.Добавить(ТекСтрока);
				ТекСтрока = "";

			КонецЕсли;
			
			ЭлементДляЗаполнения = ЭлементДляЗаполнения.Родитель;
			
			СчетчикСимволов = НомерСимвола + 1;
			Возврат;

		ИначеЕсли ТекСимвол = "," Тогда // добавление элемента текущего списка
			
			Если НЕ (ПредСимвол = "}" ИЛИ ПредСимвол = "") Тогда

				ЭлементДляЗаполнения.Значения.Добавить(ТекСтрока);
				ТекСтрока = "";

			КонецЕсли;

		Иначе
			
			ТекСтрока = ТекСтрока + ТекСимвол;

		КонецЕсли;
		
		ПредСимвол = ТекСимвол;
		
	КонецЦикла;
	
	СчетчикСимволов = НомерСимвола;
	
КонецПроцедуры // ПрочитатьДанныеСтроки()
