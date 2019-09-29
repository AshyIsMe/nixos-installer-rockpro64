{ lib, fetchFromGitHub, buildLinux, ... } @ args:

with lib;

buildLinux (args // rec {
  name = "linux-rock64";
  version = "4.19.75";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = concatStrings (intersperse "." (take 3 (splitString "." "${version}.0")));

  # branchVersion needs to be x.y
  extraMeta.branch = concatStrings (intersperse "." (take 2 (splitString "." version)));

  src = fetchFromGitHub {
    name = "${name}-${version}-source";
    owner = "lopsided98";
    repo = "linux";
    rev = "c2beaced7ae0cbe8c277967578aaff9ca7c50a9e"; 
    sha256 = "1w6cr7prrkrm170qhi6y90zbiyjp41jlsa0m1bb72cy96izg7sf8";
  };

} // (args.argsOverride or {}))
