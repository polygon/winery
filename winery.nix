{ runCommand, wineWowPackages, fetchzip, xorg, squashfsTools
, username ? "wineuser" }:
let
  Valhalla = fetchzip {
    url =
      "https://valhallaproduction.s3.us-west-2.amazonaws.com/supermassive/ValhallaSupermassiveWin_V3_0_0b3.zip";
    sha256 = "sha256-BU7Neha2idSov2m1m8bgnBEV+iqW+Hovs9rsVTBjesk=";
  };
in runCommand "winery" {
  nativeBuildInputs = [ wineWowPackages.full xorg.xorgserver squashfsTools ];
} ''
  mkdir $out
  export WINEPREFIX=$(pwd)/prefix
  mkdir home
  export HOME=$(pwd)/home

  Xvfb :8456 -screen 0 1024x768x16 &
  XVFB_PID=$!
  export DISPLAY=:8456.0
  export USER=${username}

  echo "--------------------"
  echo "Creating Wine Prefix"
  echo "--------------------"
  wine hostname

  echo "--------------------"
  echo "Installing App"
  echo "--------------------"
  wine ${Valhalla}/ValhallaSupermassiveWin_V3_0_0b3.exe /SP- /Silent /suppressmsgboxes

  echo "--------------------"
  echo "Waiting for wine to be done"
  echo "--------------------"
  wineserver --wait

  echo "--------------------"
  echo "Creating squashfs image"
  echo "--------------------"
  mksquashfs prefix $out/wineprefix.squashfs

  kill $XVFB_PID
''
