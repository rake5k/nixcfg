# https://github.com/realfolk/nix/blob/55a474544508546e70cb229235a3ff024315bd6d/lib/packages/ranger/default.nix

{ lib
, fetchFromGitHub
, python3Packages
, file
, less
}:

python3Packages.buildPythonApplication rec {
  pname = "ranger";
  version = "master";
  src = fetchFromGitHub {
    owner = "ranger";
    repo = "ranger";
    rev = "136416c7e2ecc27315fe2354ecadfe09202df7dd";
    hash = "sha256-nW4KlatugmPRPXl+XvV0/mo+DE5o8FLRrsJuiKbFGyY=";
  };
  LC_ALL = "en_US.UTF-8";
  doCheck = true;

  propagatedBuildInputs = [ file python3Packages.astroid python3Packages.pylint python3Packages.pytest ];
  #++ lib.optionals imagePreviewSupport [ python3Packages.pillow ];

  preConfigure = ''
    #UPSTREAM
    substituteInPlace ranger/__init__.py \
      --replace "DEFAULT_PAGER = 'less'" "DEFAULT_PAGER = '${lib.getBin less}/bin/less'"
    # give file previews out of the box
  '';
}
