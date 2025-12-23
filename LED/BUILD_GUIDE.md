# Инструкция по сборке iOS приложения (IPA)

Данный проект разработан для управления LED-лентой через Bluetooth (протокол Lotus Lantern/ELK-BLEDDM). 

## 1. Подготовка окружения
- **macOS:** версия 14.5 или новее.
- **Xcode:** версия 16.0 или новее (из Mac App Store).
- **xcodegen** (опционально): `brew install xcodegen`.

## 2. Создание проекта

### Вариант А: Быстрый старт через XcodeGen (Рекомендуется)
1. Откройте Терминал в папке проекта.
2. Выполните команду: `xcodegen generate`.
3. Откройте созданный файл `LEDControl.xcodeproj`.

### Вариант Б: Ручное создание
1. В Xcode: **File -> New -> Project -> iOS App**.
2. **Product Name:** `LEDControl`.
3. **Interface:** SwiftUI.
4. Удалите по умолчанию созданные файлы в папке проекта.
5. Скопируйте папку `Sources` и файл `Info.plist` в ваш проект Xcode.

## 3. Настройка Signing & Capabilities
1. В Xcode выберите проект в навигаторе (синяя иконка).
2. Выберите таргет **LEDControl**.
3. Перейдите во вкладку **Signing & Capabilities**:
   - В поле **Team** выберите ваш Apple ID.
   - Убедитесь, что **Bundle Identifier** уникален.
4. Нажмите **+ Capability** и добавьте:
   - **Background Modes**: отметьте "Uses Bluetooth LE accessories" и "Audio, AirPlay, and Picture in Picture".

## 4. Сборка и установка
1. Подключите iPhone к Mac.
2. В Xcode выберите свой iPhone в списке устройств (вверху).
3. Нажмите **Run** (Cmd + R).
4. Если вы используете бесплатный аккаунт, на iPhone перейдите в: **Настройки -> Основные -> VPN и управление устройством** -> [Ваш Apple ID] -> **Доверять**.

## 5. Экспорт в IPA
1. Установите целевое устройство **Any iOS Device (arm64)**.
2. Выберите **Product -> Archive**.
3. После завершения архивации откроется окно Organizer.
4. Нажмите **Distribute App** -> **Development** -> **Export**.
5. Полученный файл `.ipa` можно устанавливать через Apple Configurator, AltStore или TrollStore.

> [!IMPORTANT]
> Для работы таймеров в фоновом режиме убедитесь, что приложение имеет разрешение на отправку уведомлений.
> Разрешение на Bluetooth запрашивается при первом открытии вкладки "Настройки".
