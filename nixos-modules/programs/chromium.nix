{ pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      (chromium.override {
        commandLineArgs = [
          "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,UseOzonePlatform"
          "--ozone-platform=wayland"
        ];
      })
    ];
  };
}
 