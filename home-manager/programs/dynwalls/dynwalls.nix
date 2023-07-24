{ lib
, buildPythonPackage
, fetchPypi
}:

buildPythonPackage rec {
  name = "dynwalls";
  version = "25ce410";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "boi4";
    repo = "${name}";
    rev = "${version}";
    # sha256 = "1ibrwal80z27c2mh9hx85idmzilx6cpcmgc15z3lyz57bz0krigb";
  };

  # has no tests
#   doCheck = false;

#   pythonImportsCheck = [
#     "toolz.itertoolz"
#     "toolz.functoolz"
#     "toolz.dicttoolz"
#   ];

  meta = with lib; {
    # changelog = "https://github.com/pytoolz/toolz/releases/tag/${version}";
    homepage = "https://github.com/boi4/dynwalls";
    description = "Set HEIC files as wallpaper";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ boi4 ];
  };
}