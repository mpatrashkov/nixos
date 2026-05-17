{ ... }:

{
  config = {
    services.geoclue2 = {
      enableStatic = true;
      staticLatitude = 42.65566073681078;
      staticLongitude = 23.3304113473768;
      staticAccuracy = 1;
      staticAltitude = 603;
    };
  };
}
