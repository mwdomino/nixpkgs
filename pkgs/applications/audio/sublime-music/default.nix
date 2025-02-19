{ lib
, fetchFromGitLab
, python3Packages
, gobject-introspection
, gtk3
, pango
, wrapGAppsHook
, xvfb-run
, chromecastSupport ? false
, serverSupport ? false
, keyringSupport ? true
, notifySupport ? true
, libnotify
, networkSupport ? true
, networkmanager
}:

python3Packages.buildPythonApplication rec {
  pname = "sublime-music";
  version = "0.11.16";
  format = "pyproject";

  src = fetchFromGitLab {
    owner = "sublime-music";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-n77mTgElwwFaX3WQL8tZzbkPwnsyQ08OW9imSOjpBlg=";
  };

  nativeBuildInputs = [
    gobject-introspection
    python3Packages.poetry-core
    python3Packages.pythonRelaxDepsHook
    wrapGAppsHook
  ];

  # Can be removed in later versions (probably > 0.11.16)
  pythonRelaxDeps = [
    "deepdiff"
    "python-mpv"
  ];

  postPatch = ''
    sed -i "/--cov/d" setup.cfg
    sed -i "/--no-cov-on-fail/d" setup.cfg
    # https://github.com/sublime-music/sublime-music/pull/370
    # Can be removed in later versions (probably > 0.11.16)
    substituteInPlace pyproject.toml \
      --replace 'python-Levenshtein = "^0.12.0"' 'Levenshtein = ">0.12.0"'
  '';

  buildInputs = [
    gtk3
    pango
  ]
  ++ lib.optional notifySupport libnotify
  ++ lib.optional networkSupport networkmanager
  ;

  propagatedBuildInputs = with python3Packages; [
    bleach
    dataclasses-json
    deepdiff
    fuzzywuzzy
    mpv
    peewee
    pygobject3
    levenshtein
    python-dateutil
    requests
    semver
  ]
  ++ lib.optional chromecastSupport pychromecast
  ++ lib.optional keyringSupport keyring
  ++ lib.optional serverSupport bottle
  ;

  nativeCheckInputs = with python3Packages; [
    pytest
  ];

  checkPhase = ''
    ${xvfb-run}/bin/xvfb-run pytest
  '';

  pythonImportsCheck = [
    "sublime_music"
  ];

  postInstall = ''
    install -Dm444 sublime-music.desktop      -t $out/share/applications
    install -Dm444 sublime-music.metainfo.xml -t $out/share/metainfo

    for size in 16 22 32 48 64 72 96 128 192 512 1024; do
        install -Dm444 logo/rendered/"$size".png \
          $out/share/icons/hicolor/"$size"x"$size"/apps/sublime-music.png
    done
  '';

  meta = with lib; {
    description = "GTK3 Subsonic/Airsonic client";
    homepage = "https://sublimemusic.app/";
    changelog = "https://github.com/sublime-music/sublime-music/blob/v${version}/CHANGELOG.rst";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ albakham sumnerevans ];
  };
}
