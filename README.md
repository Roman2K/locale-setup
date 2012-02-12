# LocaleSetup

Rails plugin for configuring and reloading locale files, and checking for consistency between these files (missing and extraneous keys).

In development mode, all locale files are automatically reloaded between requests. Translations are updated and new files are detected and taken into account without having to restart the server.

## Directory structure

All files must be placed under `app/locales`. They can be placed and nested arbitrarily. For example:

In `app/locales/en.yml`:

    en:
      foo: "Bar"

In `app/locales/fr.yml`, or `app/locales/fr/foo.yml`:

    fr:
      foo: "Baz"

As opposed to Rails 2.3.0 RC1, the load path is not configurable.

## Configuration

To lock the current locale to `I18n.default_locale`, regardless of what `I18n.locale` has been set to, you can state the following in `config/environment.rb`:

    LocaleSetup.mono_locale!

This can be useful when you just started a new application with localization in mind, but haven't started translating it yet.

## Consistency checking

This plugin introduces a new Rake task, `rake check_locales`, that checks each locale files for consistency by comparing them to a base file. So for example if you have the following files:

In `app/locales/en.yml`:

    en:
      foo: "Bar"
      bar: "Baz"

In `app/locales/fr.yml`:

    fr:
      foo: "Zab"
      extra: "En trop"

Given the default locale configured in `config/environment.rb`:

    config.i18n.default_locale = :en
    
    # Or in Rails pre-2.3.0 RC1:
    I18n.default_locale = :en

Then running `rake check_locales` will report the following:

    $ rake check_locales
    ----- lng/fr.yml | Based on :en ------------------
    Extraneous entry: extra
    Missing entry: bar
    >> Entries: 2 | Errors: 2

Of course, with such a small number of keys, there's no need for such a tool. But as the number of keys grows (over 100), keeping all locales in sync becomes more tedious. This Rake task does all the comparison work for you, so that you can focus on translating the missing keys and deleting stale ones.
