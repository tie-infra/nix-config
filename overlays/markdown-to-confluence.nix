_: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: _: {
      markdown-to-confluence = python-final.callPackage ../pkgs/markdown-to-confluence { };
    })
  ];
}
