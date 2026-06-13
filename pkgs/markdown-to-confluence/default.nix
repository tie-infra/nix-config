{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  lxml,
  types-lxml,
  markdown,
  types-markdown,
  pymdown-extensions,
  pyyaml,
  types-pyyaml,
  requests,
  types-requests,
}:
buildPythonPackage (finalAttrs: {
  pname = "markdown-to-confluence";
  # FIXME: update to 0.6.1 or newer once mcp-atlassian supports it.
  # https://github.com/sooperset/mcp-atlassian/issues/1360
  version = "0.3.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "hunyadi";
    repo = "md2conf";
    rev = finalAttrs.version;
    hash = "sha256-VdJiwf9WwD2ICRe2j/Sn90YY3i6KxHYTu55vPPo6qc0=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    lxml
    types-lxml
    markdown
    types-markdown
    pymdown-extensions
    pyyaml
    types-pyyaml
    requests
    types-requests
  ];

  meta = {
    description = "Publish Markdown files to Confluence wiki";
    homepage = "https://github.com/hunyadi/md2conf";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.tie ];
    mainProgram = "md2conf";
  };
})
