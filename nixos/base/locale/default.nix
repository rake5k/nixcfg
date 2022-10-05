let

  localeLang = "en_US.UTF-8";
  localeFormats = "de_CH.UTF-8";

in

{
  i18n = {
    defaultLocale = localeLang;
    extraLocaleSettings = {
      LC_NUMERIC = localeFormats;
      LC_TIME = localeFormats;
      LC_MONETARY = localeFormats;
      LC_PAPER = localeFormats;
      LC_MEASUREMENT = localeFormats;
    };
  };

  location = {
    latitude = 47.5;
    longitude = 8.75;
  };

  time.timeZone = "Europe/Zurich";
}
