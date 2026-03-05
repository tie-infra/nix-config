final: _:
let
  inherit (final)
    lib
    writeShellScriptBin
    jre8
    jdk17
    jdk21
    jdk23
    jdk25
    ;

  makeJavaWrapper =
    package: name:
    writeShellScriptBin name ''
      set -eu
      exec ${lib.getExe' package "java"} "$@"
    '';
in
{
  javaWrappers = {
    java8 = makeJavaWrapper jre8 "java8";
    java17 = makeJavaWrapper jdk17 "java17";
    java21 = makeJavaWrapper jdk21 "java21";
    java23 = makeJavaWrapper jdk23 "java23";
    java25 = makeJavaWrapper jdk25 "java25";
  };
}
