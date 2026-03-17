{ pkgs }:
let
    systemPackages = with pkgs; [
        wget
        curl
        vim
        openssl
        git
    ];
in 
{
    allPackages = systemPackages;
}
