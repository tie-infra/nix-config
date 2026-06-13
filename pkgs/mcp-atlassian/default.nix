{
  lib,
  fetchFromGitHub,
  python3Packages,
}:
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "mcp-atlassian";
  version = "0.24.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Troubladore";
    repo = "mcp-atlassian";
    rev = "v${finalAttrs.version}";
    hash = "sha256-xmzhOEgM6koqUWMdwhqkphnsndzAVLv96omIfAatJr8=";
  };

  build-system = with python3Packages; [
    hatchling
    uv-dynamic-versioning
  ];

  pythonRelaxDeps = [
    "authlib"
    "python-multipart"
  ];

  pythonRemoveDeps = [
    "types-cachetools"
    "types-python-dateutil"
  ];

  dependencies = with python3Packages; [
    atlassian-python-api
    requests
    beautifulsoup4
    httpx
    mcp
    fastmcp
    fakeredis
    python-dotenv
    markdownify
    markdown
    markdown-to-confluence
    pydantic
    trio
    click
    uvicorn
    starlette
    urllib3
    thefuzz
    python-dateutil
    keyring
    cachetools
    unidecode
    truststore
  ];

  meta = {
    description = "MCP server for Atlassian tools (Confluence, Jira)";
    homepage = "https://github.com/Troubladore/mcp-atlassian";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.tie ];
    mainProgram = "mcp-atlassian";
  };
})
