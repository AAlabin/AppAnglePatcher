#!/usr/bin/env python3
"""
Command-line version of App Angle Patcher
Based on the concept from khronokernel's gist
Version 1.0.0 (2025)
"""

import os
import sys
import shutil
import plistlib
import argparse
import subprocess
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Set


class AppPatcher:
    def __init__(self, language: str = "en"):
        # Основные директории приложений
        self.applications_dir = Path("/Applications")
        self.user_applications_dir = Path("~/Applications").expanduser()
        self.backup_dir = Path("~/Applications/App-Backups").expanduser()
        
        # Текущий язык
        self.language = language
        
        # Целевые приложения для патчинга
        self.target_apps = {
            "Яндекс", "Yandex", "Яндекс браузер", "Yandex Browser",
            "Яндекс музыка", "Yandex Music", 
            "Xcode", "Simulator", "Instruments",
            "Google Chrome", "Chromium", "Microsoft Edge",
            "Brave Browser", "Discord", "Slack", 
            "Visual Studio Code", "Electron", "WhatsApp",
            "Telegram", "Signal", "Mozilla Firefox", "Opera"
        }
        
        # Доступные режимы патчинга
        self.patch_modes = {
            "gl": "--use-angle=gl",
            "metal": "--use-angle=metal",
            "vulkan": "--use-vulkan",
            "disable-gpu": "--disable-gpu",
            "custom": "custom"
        }
        
        # Локализация
        self.translations = {
            "en": {
                "backup_created": "✅ Backup created: {}",
                "backup_failed": "⚠️ Warning: Could not create backup: {}",
                "app_patched": "✅ App patched: {}",
                "launch_args": "🚀 Launch arguments: {}",
                "app_restored": "✅ App restored from backup: {}",
                "backups_cleaned": "✅ All backups removed",
                "no_backups": "ℹ️ No backups found",
                "already_patched": "ℹ️ App {} is already patched",
                "plist_not_found": "❌ Error: Info.plist not found in {}",
                "executable_not_found": "❌ Error: Could not get executable name",
                "executable_missing": "❌ Error: Executable {} not found",
                "patching_error": "❌ Error patching {}: {}",
                "restore_error": "❌ Error restoring {}: {}",
                "backup_not_found": "❌ Backup for {} not found",
                "select_patch_mode": "🎯 Available patch modes:",
                "choose_mode": "Choose mode (1-5):",
                "enter_custom_args": "Enter custom arguments:",
                "invalid_choice": "❌ Invalid choice. Try again.",
                "create_backup_question": "Create backup for {}? (y/n):",
                "yes_no_prompt": "Please enter 'y' or 'n'",
                "available_apps": "📋 Available apps for {}:",
                "selection_tip": "💡 You can select: single numbers (1), comma-separated (1,2,3),",
                "ranges_tip": "ranges (1-3), or 'all' for all apps",
                "select_apps": "🎯 Select apps for {} (or 'q' to cancel):",
                "selected_apps": "✅ Selected {} apps:",
                "confirm_selection": "❓ Confirm selection? (y/n):",
                "cancelled": "❌ Cancelled",
                "no_apps_selected": "❌ No apps selected",
                "patching_apps": "🛠️ Patching {} apps...",
                "patching_app": "📦 Patching {}...",
                "patching_success": "✅ Successfully patched",
                "patching_failed": "❌ Patching failed",
                "restoring_apps": "🔄 Restoring {} apps...",
                "restoring_app": "📦 Restoring {}...",
                "restoring_success": "✅ Successfully restored",
                "restoring_failed": "❌ Restoring failed",
                "backup_question": "Create backups? (y/n):",
                "skip_backup_error": "❌ Skip due to backup error",
                "done_patching": "✅ Done! Successfully patched {}/{} apps.",
                "done_restoring": "✅ Done! Successfully restored {}/{} apps.",
                "no_target_apps": "❌ No target apps found",
                "no_patched_apps": "ℹ️ No patched apps found",
                "confirm_cleanup": "❓ Are you sure you want to delete all backups? (y/n):",
                "cleanup_cancelled": "❌ Cancelled",
                "searching_apps": "🔍 Searching for target apps...",
                "found_apps": "📋 Found {} target apps:",
                "patched_status": " (patched)",
                "interactive_title": "🎯 App Patcher - Interactive Mode",
                "menu_options": [
                    "1. Find target apps",
                    "2. Patch all apps",
                    "3. Patch selected apps",
                    "4. Restore apps",
                    "5. Show patched apps",
                    "6. Remove backups",
                    "7. Change language",
                    "8. Exit"
                ],
                "choose_option": "🎯 Choose option (1-8):",
                "invalid_option": "❌ Invalid option. Try again.",
                "goodbye": "👋 Goodbye!",
                "language_changed": "✅ Language changed to {}",
                "current_language": "🌐 Current language: English",
                "choose_language": "Choose language:",
                "language_options": [
                    "1. English",
                    "2. Russian"
                ],
                "language_prompt": "Enter choice (1-2):"
            },
            "ru": {
                "backup_created": "✅ Резервная копия создана: {}",
                "backup_failed": "⚠️ Предупреждение: Не удалось создать резервную копию: {}",
                "app_patched": "✅ Приложение запатчено: {}",
                "launch_args": "🚀 Аргументы запуска: {}",
                "app_restored": "✅ Приложение восстановлено из резервной копии: {}",
                "backups_cleaned": "✅ Все резервные копии удалены",
                "no_backups": "ℹ️ Резервные копии не найдены",
                "already_patched": "ℹ️ Приложение {} уже запатчено",
                "plist_not_found": "❌ Ошибка: Info.plist не найден в {}",
                "executable_not_found": "❌ Ошибка: Не удалось получить имя исполняемого файла",
                "executable_missing": "❌ Ошибка: Исполняемый файл {} не найден",
                "patching_error": "❌ Ошибка при патчинге {}: {}",
                "restore_error": "❌ Ошибка при восстановлении {}: {}",
                "backup_not_found": "❌ Резервная копия для {} не найдена",
                "select_patch_mode": "🎯 Доступные режимы патчинга:",
                "choose_mode": "Выберите режим (1-5):",
                "enter_custom_args": "Введите пользовательские аргументы:",
                "invalid_choice": "❌ Неверный выбор. Попробуйте снова.",
                "create_backup_question": "Создать резервную копию для {}? (y/n):",
                "yes_no_prompt": "Пожалуйста, введите 'y' или 'n'",
                "available_apps": "📋 Доступные приложения для {}:",
                "selection_tip": "💡 Можно выбрать: отдельные номера (1), через запятую (1,2,3),",
                "ranges_tip": "диапазоны (1-3), или 'all' для всех приложений",
                "select_apps": "🎯 Выберите приложения для {} (или 'q' для отмены):",
                "selected_apps": "✅ Выбрано {} приложений:",
                "confirm_selection": "❓ Подтвердить выбор? (y/n):",
                "cancelled": "❌ Отменено",
                "no_apps_selected": "❌ Не выбрано ни одного приложения",
                "patching_apps": "🛠️ Патчинг {} приложений...",
                "patching_app": "📦 Патчинг {}...",
                "patching_success": "✅ Успешно запатчено",
                "patching_failed": "❌ Ошибка патчинга",
                "restoring_apps": "🔄 Восстановление {} приложений...",
                "restoring_app": "📦 Восстановление {}...",
                "restoring_success": "✅ Успешно восстановлено",
                "restoring_failed": "❌ Ошибка восстановления",
                "backup_question": "Создавать резервные копии? (y/n):",
                "skip_backup_error": "❌ Пропускаем из-за ошибки резервного копирования",
                "done_patching": "✅ Готово! Успешно запатчено {}/{} приложений.",
                "done_restoring": "✅ Готово! Успешно восстановлено {}/{} приложений.",
                "no_target_apps": "❌ Целевые приложения не найдены",
                "no_patched_apps": "ℹ️ Запатченные приложения не найдены",
                "confirm_cleanup": "❓ Вы уверены, что хотите удалить все резервные копии? (y/n):",
                "cleanup_cancelled": "❌ Отменено",
                "searching_apps": "🔍 Поиск целевых приложений...",
                "found_apps": "📋 Найдено {} целевых приложений:",
                "patched_status": " (запатчено)",
                "interactive_title": "🎯 App Patcher - Интерактивный режим",
                "menu_options": [
                    "1. Найти целевые приложения",
                    "2. Запатчить все приложения",
                    "3. Запатчить выбранные приложения",
                    "4. Восстановить приложения",
                    "5. Показать запатченные приложения",
                    "6. Удалить резервные копии",
                    "7. Сменить язык",
                    "8. Выход"
                ],
                "choose_option": "🎯 Выберите опцию (1-8):",
                "invalid_option": "❌ Неверный выбор. Попробуйте снова.",
                "goodbye": "👋 До свидания!",
                "language_changed": "✅ Язык изменен на {}",
                "current_language": "🌐 Текущий язык: Русский",
                "choose_language": "Выберите язык:",
                "language_options": [
                    "1. Английский",
                    "2. Русский"
                ],
                "language_prompt": "Введите выбор (1-2):"
            }
        }
    
    def t(self, key: str, *args) -> str:
        """Получить переведенную строку"""
        translation = self.translations[self.language].get(key, key)
        return translation.format(*args) if args else translation
    
    def set_language(self, language: str):
        """Установить язык"""
        if language in self.translations:
            self.language = language
    
    def find_target_applications(self) -> Dict[str, Path]:
        """Поиск всех целевых приложений в системных директориях"""
        target_apps = {}
        
        # Директории для поиска приложений
        search_dirs = [self.applications_dir, self.user_applications_dir]
        
        for search_dir in search_dirs:
            if not search_dir.exists():
                continue
            
            # Рекурсивный поиск .app bundles
            for app_path in search_dir.rglob("*.app"):
                app_name = app_path.stem
                
                if self._is_target_app(app_name, app_path):
                    target_apps[app_name] = app_path
        
        return target_apps
    
    def _is_target_app(self, app_name: str, app_path: Path) -> bool:
        """Проверка, является ли приложение целевым для патчинга"""
        # Проверка по имени приложения
        for target in self.target_apps:
            if target.lower() in app_name.lower():
                return True
        
        # Проверка на приложения Xcode
        if self._is_xcode_related(app_name, app_path):
            return True
        
        # Проверка на Chromium/Electron приложения через Info.plist
        try:
            info_plist = app_path / "Contents" / "Info.plist"
            if info_plist.exists():
                with open(info_plist, 'rb') as f:
                    plist_data = plistlib.load(f)
                
                bundle_id = plist_data.get('CFBundleIdentifier', '')
                executable = plist_data.get('CFBundleExecutable', '')
                
                # Проверка по bundle identifier и имени исполняемого файла
                if any(x in bundle_id.lower() for x in ['chromium', 'chrome', 'electron', 'yandex']):
                    return True
                
                if any(x in executable.lower() for x in ['chromium', 'chrome', 'electron']):
                    return True
        except Exception as e:
            print(f"   Warning: Could not read Info.plist for {app_name}: {e}")
        
        return False
    
    def _is_xcode_related(self, app_name: str, app_path: Path) -> bool:
        """Проверка, относится ли приложение к Xcode"""
        xcode_indicators = ['xcode', 'simulator', 'instruments']
        app_name_lower = app_name.lower()
        path_lower = str(app_path).lower()
        
        # Проверка по имени приложения и пути
        for indicator in xcode_indicators:
            if indicator in app_name_lower:
                return True
        
        if '/xcode.app/contents/applications/' in path_lower:
            return True
        
        # Проверка через Info.plist
        try:
            info_plist = app_path / "Contents" / "Info.plist"
            if info_plist.exists():
                with open(info_plist, 'rb') as f:
                    plist_data = plistlib.load(f)
                
                bundle_id = plist_data.get('CFBundleIdentifier', '')
                if 'com.apple.dt' in bundle_id or 'xcode' in bundle_id.lower():
                    return True
        except:
            pass
        
        return False
    
    def backup_app(self, app_name: str, app_path: Path) -> bool:
        """Создание резервной копии приложения перед патчингом"""
        try:
            self.backup_dir.mkdir(parents=True, exist_ok=True)
            backup_path = self.backup_dir / f"{app_name}.app"
            
            # Удаляем старый backup если существует
            if backup_path.exists():
                shutil.rmtree(backup_path)
            
            # Копируем приложение в backup директориу
            shutil.copytree(app_path, backup_path)
            print(self.t("backup_created", backup_path))
            return True
        except Exception as e:
            print(self.t("backup_failed", e))
            return False
    
    def is_already_patched(self, app_path: Path) -> bool:
        """Проверка, было ли приложение уже запатчено"""
        try:
            macos_dir = app_path / "Contents" / "MacOS"
            if not macos_dir.exists():
                return False
            
            # Ищем оригинальный исполняемый файл
            for item in macos_dir.iterdir():
                if item.name.endswith('.original'):
                    return True
            
            return False
        except:
            return False
    
    def patch_app(self, app_name: str, app_path: Path, patch_mode: str = "gl", custom_args: str = "") -> bool:
        """Патчинг .app bundle для запуска с указанными аргументами"""
        try:
            # Проверяем, не запатчено ли уже приложение
            if self.is_already_patched(app_path):
                print(self.t("already_patched", app_name))
                return True
            
            # Получаем информацию о приложении
            info_plist = app_path / "Contents" / "Info.plist"
            if not info_plist.exists():
                print(self.t("plist_not_found", app_path))
                return False
            
            with open(info_plist, 'rb') as f:
                plist_data = plistlib.load(f)
            
            executable_name = plist_data.get('CFBundleExecutable', '')
            if not executable_name:
                print(self.t("executable_not_found"))
                return False
            
            # Путь к оригинальному исполняемому файлу
            macos_dir = app_path / "Contents" / "MacOS"
            original_executable = macos_dir / executable_name
            
            if not original_executable.exists():
                print(self.t("executable_missing", executable_name))
                return False
            
            # Переименовываем оригинальный исполняемый файл
            original_backup = macos_dir / f"{executable_name}.original"
            if original_backup.exists():
                original_backup.unlink()
            
            original_executable.rename(original_backup)
            
            # Формируем аргументы запуска
            launch_args = self.patch_modes.get(patch_mode, "--use-angle=gl")
            if patch_mode == "custom" and custom_args:
                launch_args = custom_args
            
            # Создаем новый скрипт-загрузчик
            new_executable = macos_dir / executable_name
            
            script_content = f'''#!/bin/bash

# Auto-launch script for {app_name}
ORIGINAL_EXECUTABLE="$(dirname "$0")/{executable_name}.original"
APP_NAME="{app_name}"

echo "Launching $APP_NAME with arguments: {launch_args}"

# Запускаем оригинальный исполняемый файл с указанными аргументами
exec "$ORIGINAL_EXECUTABLE" {launch_args} "$@"
'''
            
            new_executable.write_text(script_content)
            new_executable.chmod(0o755)  # Делаем исполняемым
            
            print(self.t("app_patched", new_executable))
            print(self.t("launch_args", launch_args))
            
            return True
            
        except Exception as e:
            print(self.t("patching_error", app_name, e))
            # Пытаемся восстановить оригинал в случае ошибки
            try:
                if 'original_backup' in locals() and original_backup.exists():
                    if new_executable.exists():
                        new_executable.unlink()
                    original_backup.rename(original_executable)
            except:
                pass
            return False
    
    def restore_app(self, app_name: str, app_path: Path) -> bool:
        """Восстановление оригинального приложения из резервной копии"""
        try:
            backup_path = self.backup_dir / f"{app_name}.app"
            
            if not backup_path.exists():
                print(self.t("backup_not_found", app_name))
                return False
            
            # Удаляем патченное приложение
            if app_path.exists():
                shutil.rmtree(app_path)
            
            # Восстанавливаем из backup
            shutil.copytree(backup_path, app_path)
            print(self.t("app_restored", backup_path))
            
            return True
            
        except Exception as e:
            print(self.t("restore_error", app_name, e))
            return False
    
    def list_patched_apps(self) -> List[str]:
        """Получение списка запатченных приложений (имеющих резервные копии)"""
        patched_apps = []
        
        if not self.backup_dir.exists():
            return patched_apps
        
        for backup in self.backup_dir.glob("*.app"):
            patched_apps.append(backup.stem)
        
        return patched_apps
    
    def cleanup_backups(self):
        """Удаление всех резервных копий"""
        if self.backup_dir.exists():
            shutil.rmtree(self.backup_dir)
            print(self.t("backups_cleaned"))
        else:
            print(self.t("no_backups"))


def parse_selection(input_str: str, max_number: int) -> Set[int]:
    """
    Парсинг ввода пользователя для выбора нескольких приложений
    Поддерживает форматы: 1, 1,2,3, 1-3, 1,3-5, all
    """
    input_str = input_str.strip().lower()
    
    if input_str == 'all':
        return set(range(1, max_number + 1))
    
    selected_numbers = set()
    
    # Разделяем по запятым
    parts = input_str.split(',')
    
    for part in parts:
        part = part.strip()
        if '-' in part:
            # Диапазон чисел (например, 1-3)
            range_parts = part.split('-')
            if len(range_parts) == 2:
                try:
                    start = int(range_parts[0])
                    end = int(range_parts[1])
                    if 1 <= start <= end <= max_number:
                        selected_numbers.update(range(start, end + 1))
                    else:
                        print(f"   ❌ Invalid range: {part}")
                except ValueError:
                    print(f"   ❌ Invalid range format: {part}")
        else:
            # Одиночное число
            try:
                num = int(part)
                if 1 <= num <= max_number:
                    selected_numbers.add(num)
                else:
                    print(f"   ❌ Number out of range: {num}")
            except ValueError:
                print(f"   ❌ Invalid number format: {part}")
    
    return selected_numbers


def select_apps_from_list(patcher: AppPatcher, apps_list: List[Tuple[str, Path]], action: str) -> List[Tuple[str, Path]]:
    """
    Выбор приложений из списка с возможностью множественного выбора
    """
    if not apps_list:
        print(patcher.t("no_target_apps"))
        return []
    
    print(patcher.t("available_apps", action))
    for i, (name, path) in enumerate(apps_list, 1):
        status = patcher.t("patched_status") if name in patcher.list_patched_apps() else ""
        print(f"   {i}. {name}{status}")
    
    print(f"   {patcher.t('selection_tip')}")
    print(f"   {patcher.t('ranges_tip')}")
    
    while True:
        try:
            selection = input(patcher.t("select_apps", action)).strip()
            
            if selection.lower() in ['q', 'quit', 'exit', 'cancel']:
                print(patcher.t("cancelled"))
                return []
            
            if not selection:
                print(patcher.t("no_apps_selected"))
                continue
            
            selected_numbers = parse_selection(selection, len(apps_list))
            
            if not selected_numbers:
                print(patcher.t("no_apps_selected"))
                continue
            
            selected_apps = []
            for num in sorted(selected_numbers):
                selected_apps.append(apps_list[num - 1])
            
            # Подтверждение выбора
            print(patcher.t("selected_apps", len(selected_apps)))
            for i, (name, path) in enumerate(selected_apps, 1):
                print(f"   {i}. {name}")
            
            confirm = input(patcher.t("confirm_selection")).strip().lower()
            if confirm in ['y', 'yes', 'д', 'да']:
                return selected_apps
            else:
                print(patcher.t("cancelled"))
                
        except Exception as e:
            print(f"❌ Input processing error: {e}")
            continue


def select_patch_mode(patcher: AppPatcher) -> Tuple[str, str]:
    """Выбор режима патчинга"""
    modes = [
        ("1", "gl", "OpenGL (--use-angle=gl)"),
        ("2", "metal", "Metal (--use-angle=metal)"),
        ("3", "vulkan", "Vulkan (--use-vulkan)"),
        ("4", "disable-gpu", "Disable GPU (--disable-gpu)"),
        ("5", "custom", "Custom arguments")
    ]
    
    print(patcher.t("select_patch_mode"))
    for num, mode, desc in modes:
        print(f"   {num}. {desc}")
    
    while True:
        choice = input(patcher.t("choose_mode")).strip()
        for num, mode, desc in modes:
            if choice == num:
                if mode == "custom":
                    custom_args = input(patcher.t("enter_custom_args")).strip()
                    return mode, custom_args
                return mode, ""
        
        print(patcher.t("invalid_choice"))


def ask_backup_confirmation(patcher: AppPatcher, app_name: str) -> bool:
    """Запрос подтверждения создания резервной копии"""
    while True:
        response = input(patcher.t("create_backup_question", app_name)).strip().lower()
        if response in ['y', 'yes', 'д', 'да']:
            return True
        elif response in ['n', 'no', 'н', 'нет']:
            return False
        else:
            print(patcher.t("yes_no_prompt"))


def change_language(patcher: AppPatcher) -> bool:
    """Смена языка интерфейса"""
    print(patcher.t("choose_language"))
    print(f"   1. English")
    print(f"   2. Русский")
    
    while True:
        choice = input(patcher.t("language_prompt")).strip()
        if choice == "1":
            patcher.set_language("en")
            print(patcher.t("language_changed", "English"))
            return True
        elif choice == "2":
            patcher.set_language("ru")
            print(patcher.t("language_changed", "Russian"))
            return True
        else:
            print(patcher.t("invalid_choice"))


def interactive_mode(patcher: AppPatcher):
    """Интерактивный режим работы с программой"""
    while True:
        print("\n" + "="*50)
        print(patcher.t("interactive_title"))
        print("="*50)
        
        # Показываем текущий язык
        print(patcher.t("current_language"))
        print()
        
        # Показываем меню
        for option in patcher.t("menu_options"):
            print(option)
        
        choice = input(f"\n{patcher.t('choose_option')} ").strip()
        
        if choice == "1":
            print(patcher.t("searching_apps"))
            apps = patcher.find_target_applications()
            apps_list = list(apps.items())
            
            if not apps_list:
                print(patcher.t("no_target_apps"))
                continue
            
            print(patcher.t("found_apps", len(apps_list)))
            for i, (name, path) in enumerate(apps_list, 1):
                status = patcher.t("patched_status") if name in patcher.list_patched_apps() else ""
                print(f"   {i}. {name}{status}")
        
        elif choice == "2":
            print(patcher.t("searching_apps"))
            apps = patcher.find_target_applications()
            apps_list = list(apps.items())
            
            if not apps_list:
                print(patcher.t("no_target_apps"))
                continue
            
            patch_mode, custom_args = select_patch_mode(patcher)
            backup_choice = input(patcher.t("backup_question")).strip().lower() in ['y', 'yes', 'д', 'да']
            
            print(patcher.t("patching_apps", len(apps_list)))
            success_count = 0
            
            for name, path in apps_list:
                print(patcher.t("patching_app", name))
                
                if backup_choice:
                    if not patcher.backup_app(name, path):
                        print(patcher.t("skip_backup_error"))
                        continue
                
                if patcher.patch_app(name, path, patch_mode, custom_args):
                    success_count += 1
                    print(patcher.t("patching_success"))
                else:
                    print(patcher.t("patching_failed"))
            
            print(patcher.t("done_patching", success_count, len(apps_list)))
        
        elif choice == "3":
            print(patcher.t("searching_apps"))
            apps = patcher.find_target_applications()
            apps_list = list(apps.items())
            
            if not apps_list:
                print(patcher.t("no_target_apps"))
                continue
            
            selected_apps = select_apps_from_list(patcher, apps_list, "patching")
            if not selected_apps:
                continue
            
            patch_mode, custom_args = select_patch_mode(patcher)
            backup_choice = input(patcher.t("backup_question")).strip().lower() in ['y', 'yes', 'д', 'да']
            
            print(patcher.t("patching_apps", len(selected_apps)))
            success_count = 0
            
            for name, path in selected_apps:
                print(patcher.t("patching_app", name))
                
                if backup_choice:
                    if not patcher.backup_app(name, path):
                        print(patcher.t("skip_backup_error"))
                        continue
                
                if patcher.patch_app(name, path, patch_mode, custom_args):
                    success_count += 1
                    print(patcher.t("patching_success"))
                else:
                    print(patcher.t("patching_failed"))
            
            print(patcher.t("done_patching", success_count, len(selected_apps)))
        
        elif choice == "4":
            patched_apps = patcher.list_patched_apps()
            
            if not patched_apps:
                print(patcher.t("no_patched_apps"))
                continue
            
            # Получаем полную информацию о запатченных приложениях
            all_apps = patcher.find_target_applications()
            apps_to_restore = []
            
            for app_name in patched_apps:
                if app_name in all_apps:
                    apps_to_restore.append((app_name, all_apps[app_name]))
            
            if not apps_to_restore:
                print(patcher.t("no_patched_apps"))
                continue
            
            selected_apps = select_apps_from_list(patcher, apps_to_restore, "restoring")
            if not selected_apps:
                continue
            
            print(patcher.t("restoring_apps", len(selected_apps)))
            success_count = 0
            
            for name, path in selected_apps:
                print(patcher.t("restoring_app", name))
                if patcher.restore_app(name, path):
                    success_count += 1
                    print(patcher.t("restoring_success"))
                else:
                    print(patcher.t("restoring_failed"))
            
            print(patcher.t("done_restoring", success_count, len(selected_apps)))
        
        elif choice == "5":
            patched_apps = patcher.list_patched_apps()
            
            if patched_apps:
                print("📦 " + ("Patched apps:" if patcher.language == "en" else "Запатченные приложения:"))
                for app_name in patched_apps:
                    print(f"   • {app_name}")
            else:
                print(patcher.t("no_patched_apps"))
        
        elif choice == "6":
            confirm = input(patcher.t("confirm_cleanup")).strip().lower()
            if confirm in ['y', 'yes', 'д', 'да']:
                patcher.cleanup_backups()
            else:
                print(patcher.t("cleanup_cancelled"))
        
        elif choice == "7":
            change_language(patcher)
        
        elif choice == "8":
            print(patcher.t("goodbye"))
            break
        
        else:
            print(patcher.t("invalid_option"))


def main():
    """Основная функция программы"""
    parser = argparse.ArgumentParser(description="Patch .app bundles to launch with various flags")
    parser.add_argument('--list', action='store_true', help='Show target applications')
    parser.add_argument('--patch', action='store_true', help='Patch all target applications')
    parser.add_argument('--app', type=str, help='Patch specific application')
    parser.add_argument('--restore', type=str, help='Restore specific application')
    parser.add_argument('--restore-all', action='store_true', help='Restore all applications')
    parser.add_argument('--patched', action='store_true', help='Show patched applications')
    parser.add_argument('--cleanup', action='store_true', help='Remove backups')
    parser.add_argument('--mode', type=str, choices=['gl', 'metal', 'vulkan', 'disable-gpu', 'custom'], 
                       default='gl', help='Patch mode (default: gl)')
    parser.add_argument('--args', type=str, help='Custom arguments for custom mode')
    parser.add_argument('--no-backup', action='store_true', help='Do not create backups')
    parser.add_argument('--lang', type=str, choices=['en', 'ru'], default='en', help='Interface language')
    
    args = parser.parse_args()
    
    # Создаем патчер с выбранным языком
    patcher = AppPatcher(language=args.lang)
    
    # Обработка аргументов командной строки
    if args.list:
        print(patcher.t("searching_apps"))
        apps = patcher.find_target_applications()
        print(patcher.t("found_apps", len(apps)))
        for name, path in apps.items():
            status = patcher.t("patched_status") if name in patcher.list_patched_apps() else ""
            print(f"   • {name}{status}")
    
    elif args.patch:
        print(patcher.t("searching_apps"))
        apps = patcher.find_target_applications()
        
        if not apps:
            print(patcher.t("no_target_apps"))
            return
        
        print(patcher.t("patching_apps", len(apps)))
        success_count = 0
        
        for name, path in apps.items():
            print(patcher.t("patching_app", name))
            
            # Создаем backup если не указано обратное
            if not args.no_backup:
                patcher.backup_app(name, path)
            
            if patcher.patch_app(name, path, args.mode, args.args):
                success_count += 1
                print(patcher.t("patching_success"))
            else:
                print(patcher.t("patching_failed"))
        
        print(patcher.t("done_patching", success_count, len(apps)))
    
    elif args.app:
        print(f"🔍 Searching for {args.app}...")
        apps = patcher.find_target_applications()
        found_apps = [(name, path) for name, path in apps.items() if args.app.lower() in name.lower()]
        
        if not found_apps:
            print(f"❌ Application '{args.app}' not found")
            return
        
        if len(found_apps) > 1:
            print("🔍 Multiple applications found:")
            for i, (name, path) in enumerate(found_apps, 1):
                print(f"   {i}. {name}")
            
            try:
                choice = int(input("Select application: ")) - 1
                if 0 <= choice < len(found_apps):
                    name, path = found_apps[choice]
                else:
                    print("❌ Invalid selection")
                    return
            except ValueError:
                print("❌ Invalid input")
                return
        else:
            name, path = found_apps[0]
        
        # Создаем backup если не указано обратное
        if not args.no_backup:
            patcher.backup_app(name, path)
        
        print(patcher.t("patching_app", name))
        if patcher.patch_app(name, path, args.mode, args.args):
            print(f"✅ {name} successfully patched!")
        else:
            print(f"❌ Error patching {name}")
    
    elif args.restore:
        apps = patcher.find_target_applications()
        found_apps = [(name, path) for name, path in apps.items() if args.restore.lower() in name.lower()]
        
        if not found_apps:
            print(f"❌ Application '{args.restore}' not found")
            return
        
        if len(found_apps) > 1:
            print("🔍 Multiple applications found:")
            for i, (name, path) in enumerate(found_apps, 1):
                print(f"   {i}. {name}")
            
            try:
                choice = int(input("Select application: ")) - 1
                if 0 <= choice < len(found_apps):
                    name, path = found_apps[choice]
                else:
                    print("❌ Invalid selection")
                    return
            except ValueError:
                print("❌ Invalid input")
                return
        else:
            name, path = found_apps[0]
        
        print(patcher.t("restoring_app", name))
        if patcher.restore_app(name, path):
            print(f"✅ {name} successfully restored!")
        else:
            print(f"❌ Error restoring {name}")
    
    elif args.restore_all:
        patched_apps = patcher.list_patched_apps()
        
        if not patched_apps:
            print(patcher.t("no_patched_apps"))
            return
        
        apps = patcher.find_target_applications()
        restored_count = 0
        
        for app_name in patched_apps:
            if app_name in apps:
                print(patcher.t("restoring_app", app_name))
                if patcher.restore_app(app_name, apps[app_name]):
                    restored_count += 1
        
        print(patcher.t("done_restoring", restored_count, len(patched_apps)))
    
    elif args.patched:
        patched_apps = patcher.list_patched_apps()
        
        if patched_apps:
            print("📦 " + ("Patched applications:" if patcher.language == "en" else "Запатченные приложения:"))
            for app_name in patched_apps:
                print(f"   • {app_name}")
        else:
            print(patcher.t("no_patched_apps"))
    
    elif args.cleanup:
        confirm = input(patcher.t("confirm_cleanup")).strip().lower()
        if confirm in ['y', 'yes', 'д', 'да']:
            patcher.cleanup_backups()
        else:
            print(patcher.t("cleanup_cancelled"))
    
    else:
        # Интерактивный режим
        interactive_mode(patcher)


if __name__ == "__main__":
    main()
