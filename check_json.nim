import httpclient, json, net, os, sets, strutils, logging, unittest, ospaths, sequtils

const
  allow_broken_url* = false     ## Allow broken Repo URLs
  allow_missing_nimble* = false ## Allow missing ``plugin.json`` files
  check_nimble_file* = true     ## Check if repos have ``plugin.json`` file
  http_timeout* = 3_000         ## Timeout. Below ~3000 false positives happen?
  tags_max_len* = 32            ## Maximum lenght for the string in tags
  tags_maximum* = 10            ## Maximum number of tags allowed on the list
  vcs_types* = ["git"]          ## Valid known Version Control Systems.
  tags_blacklist* = ["nimrod", "nim", "nimwc"] ## Tags that should be not allowed.
  keys_required* = ["name", "foldername", "version", "url", "method", "tags",
                    "description", "license", "web", "requires", "sustainability"]
  keys_empty_string* = ["sustainability", "email"]
  packages_json_str = readFile(currentSourcePath().parentDir / "plugins.json")
  hosts_skip* = [
    "https://bitbucket",
    "https://gitlab.3dicc",
    "https://notabug",
  ] ## Hostnames to skip checks, for reliability, wont like direct HTTP GET?.
  licenses* = [
    "allegro 4 giftware",
    "apache",
    "apache2",
    "apache2.0",
    "apache 2.0",
    "apache version 2.0",
    "apache license 2.0",
    "bsd",
    "bsd2",
    "bsd-2",
    "bsd3",
    "bsd-3",
    "bsd 2-clause",
    "bsd 3-clause",
    "cc0",
    "gpl",
    "gpl2",
    "gpl3",
    "gplv2",
    "gplv3",
    "lgpl",
    "lgplv2",
    "lgplv2.1",
    "lgplv3",
    "mit",
    "ms-pl",
    "mpl",
    "wtfpl",
    "libpng",
    "zlib",
    "isc",
    "unlicense",
    "ppl",
    # Not concrete Licenses, but some rare cases observed on the JSON.
    "fontconfig",
    "public domain",
    "lgplv3 or gplv2",
    "openssl and ssleay",
    "apache 2.0 or gplv2",
    "mit or apache 2.0",
    "lgpl with static linking exception",
    "peer production license",
    "peers production license",
  ]  ## All valid known licences for Nimble packages, on lowercase.

let
  packages_json* = parseJson(packages_json_str).getElems         ## ``string`` to ``JsonNode``
  pckgs_list* = packages_json
  client* = newHttpClient(timeout = http_timeout) ## HTTP Client with Timeout
  console_logger* = newConsoleLogger(fmtStr = verboseFmtStr) ## Basic Logger
addHandler(console_logger)

func strip_ending_slash*(url: string): string =
  ## Strip the ending '/' if any else return the same string.
  if url[url.len - 1] == '/':      # if ends in '/'
    result = url[0 .. url.len - 2] # Remove it.
  else:
    result = url

func preprocess_url*(url, name: string): string =
  ## Take **Normalized** URL & Name return Download link. GitHub & GitLab supported.
  if url.startswith("https://github.com/"):
    result = url.replace("https://github.com/", "https://raw.githubusercontent.com/")
    result = strip_ending_slash(result)
    result &= "/master/plugin.json"
  elif url.startswith("https://0xacab.org/") or url.startswith("https://gitlab."):
    result = strip_ending_slash(result)
    result &= "/raw/master/plugin.json"

proc nimble_file_exists*(url, name: string): string =
  ## Take **Normalized** URL & Name try to Fetch the Nimble file. Needs SSL.
  debug url
  if url.startswith("http"):
    try:
      let urly = preprocess_url(url, name)
      doAssert urly.len > 0, "GIT or HG Hosting not supported: " & url
      doAssert client.get(url).status == $Http200 # Check that Repo Exists.
      result = urly
    except TimeoutError, HttpRequestError, AssertionError:
      warn("HttpClient request error fetching repo: " & url, getCurrentExceptionMsg())
    except:
      warn("Unkown Error fetching repo: " & url, getCurrentExceptionMsg())
  else:
    result = url  # SSH or other non-HTTP kinda URLs?

proc git_repo_exists*(url: string): string =
  ## Take **Normalized** URL try to Fetch the Git repo index page. Needs SSL.
  debug url
  if url.startswith("http"):
    try:
      doAssert client.get(url).status == $Http200 # Check that Repo Exists.
      result = url
    except TimeoutError, HttpRequestError, AssertionError:
      warn("HttpClient request error fetching repo: " & url, getCurrentExceptionMsg())
    except:
      warn("Unkown Error fetching repo: " & url, getCurrentExceptionMsg())
  else:
    result = url  # SSH or other non-HTTP kinda URLs?


suite "Packages consistency testing":

  var
    names = initSet[string]()
    urls = initSet[string]()

  test "Check Basic Structure":
    for pdata in pckgs_list:
      for key in keys_required:
        if pdata.hasKey(key):
          if key == "tags":
            check pdata[key].kind == JArray  # Tags is array
            check pdata[key].len > 0         # Tags can not be empty
          elif key in keys_empty_string:
            check pdata[key].kind == JString # Other keys are string
          else:
            check pdata[key].kind == JString # Other keys are string
            check pdata[key].str.len > 0     # No field can be empty string
        else:
          fatal("Missing Keys on the JSON (making it invalid): " & $key)

  test "Check Tags":
    for pdata in pckgs_list:
      check pdata["tags"].len > 0            # Minimum number of tags
      check tags_maximum > pdata["tags"].len # Maximum number of tags
      for tagy in pdata["tags"]:
        check tagy.str.strip.len >= 1     # No empty string tags
        check tags_max_len > tagy.str.len # Maximum lenght of tags
        check tagy.str.strip.toLowerAscii notin tags_blacklist

  test "Check Methods":
    for pdata in pckgs_list:
      var metod = pdata["method"]
      check metod.kind == JString
      check metod.str.len == pdata["method"].str.strip.len
      check metod.str in vcs_types

  test "Check Licenses":
    for pdata in pckgs_list:
      var license = pdata["license"]
      check license.kind == JString
      check license.str.len == license.str.strip.len
      check(not license.str.strip.startsWith("the ")) # Dont use "The GPL" etc
      check license.str.normalize in licenses

  test "Check Names":
    for pdata in pckgs_list:
      var name = pdata["name"]
      check name.kind == JString
      check name.str.len == name.str.strip.len # No Whitespace
      if name.str.strip notin names:
        names.incl name.str.strip.toLowerAscii
      else:
        fatal("Package by that name already exists: " & $name)

  test "Check Versions":
    for pdata in pckgs_list:
      var name = pdata["version"]
      check name.kind == JString
      check name.str.len == name.str.strip.len # No Whitespace
      check parseFloat(name.str) is float

  test "Check Requires":
    for pdata in pckgs_list:
      var name = pdata["requires"]
      check name.kind == JString
      check name.str.len == name.str.strip.len # No Whitespace
      check parseFloat(name.str) is float
      check parseFloat(name.str) >= 5.0  # First Version with this

  test "Check Foldernames":
    for pdata in pckgs_list:
      var name = pdata["foldername"]
      check name.kind == JString
      check name.str.len == name.str.strip.len # No Whitespace
      check name.str.len > 0

  test "Check Webs Off-Line":
    for pdata in pckgs_list:
      if pdata.hasKey("web"):
        var weeb = pdata["web"]
        check weeb.kind == JString
        check weeb.str.len == weeb.str.strip.len
        check weeb.str.strip.startswith("http")
        # Insecure Link URLs
        check(not weeb.str.strip.startsWith("http://github.com"))
        check(not weeb.str.strip.startsWith("http://gitlab.com"))
        check(not weeb.str.strip.startsWith("http://0xacab.org"))

  test "Check Webs On-Line":
    when defined(ssl):
      var existent, nonexistent, nimble_existent, nimble_nonexistent: seq[string]
      for pdata in pckgs_list:
        var
          skip: bool
          url = pdata["web"].str.strip.toLowerAscii
          name = pdata["name"].str.normalize

        # Some hostings randomly timeout or fail sometimes, skip them.
        for skipurl in hosts_skip:
          if url.startsWith(skipurl):
            skip = true
        if skip: continue

        # Check that the Git Repo actually exists.
        var this_repo = git_repo_exists(url=url) # Fetch test.
        if this_repo.len > 0:
          existent.add this_repo
        else:
          nonexistent.add url

  test "Check Sustainability On-Line":
    when defined(ssl):
      var existent, nonexistent, nimble_existent, nimble_nonexistent: seq[string]
      for pdata in pckgs_list:
        var
          skip: bool
          url = pdata["sustainability"].str.strip.toLowerAscii
          name = pdata["name"].str.normalize

        if url.startsWith("http"):
          # Some hostings randomly timeout or fail sometimes, skip them.
          for skipurl in hosts_skip:
            if url.startsWith(skipurl):
              skip = true
          if skip: continue

          # Check that the Git Repo actually exists.
          var this_repo = git_repo_exists(url=url) # Fetch test.
          if this_repo.len > 0:
            existent.add this_repo
          else:
            nonexistent.add url

  test "Check URLs Off-Line":
    for pdata in pckgs_list:
      var url = pdata["url"].str
      check url.len == url.strip.len # No Whitespace
      # Insecure Link URLs
      check(not url.strip.startsWith("git://github.com/"))
      check(not url.strip.startsWith("http://github.com"))
      check(not url.strip.startsWith("http://gitlab.com"))
      check(not url.strip.startsWith("http://0xacab.org"))
      if url notin urls:
        urls.incl url
      else:
        fatal("Package by that URL already exists: " & $url)

  test "Check URLs On-Line":
    when defined(ssl):
      var existent, nonexistent, nimble_existent, nimble_nonexistent: seq[string]
      for pdata in pckgs_list:
        var
          skip: bool
          url = pdata["url"].str.strip.toLowerAscii
          name = pdata["name"].str.normalize

        # Some hostings randomly timeout or fail sometimes, skip them.
        for skipurl in hosts_skip:
          if url.startsWith(skipurl):
            skip = true
        if skip: continue

        # Check that the Git Repo actually exists.
        var this_repo = git_repo_exists(url=url) # Fetch test.
        if this_repo.len > 0:
          existent.add this_repo
        else:
          nonexistent.add url

        # Check for Nimble Files on Existent Repos.
        if this_repo.len > 0 and check_nimble_file:
          var this_nimble = nimble_file_exists(url=this_repo, name=name)
          if this_nimble.len > 0:
            nimble_existent.add this_nimble
          else:
            nimble_nonexistent.add url

      # Warn or Assert the possible errors at the end.
      if nonexistent.len > 0 and allow_broken_url:
        warn "Missing repos list:\n" & nonexistent.join("\n  ")
        warn "Missing repos count: " & $nonexistent.len & " of " & $pckgs_list.len
      else:
        doAssert nonexistent.len == 0, "Missing repos: Broken Packages."
      if nimble_nonexistent.len > 0 and allow_missing_nimble:
        warn "Missing Nimble files:\n" & nimble_nonexistent.join("\n  ")
        warn "Missing Nimble files count: " & $nimble_nonexistent.len & " of " & $pckgs_list.len
      else:
        doAssert nimble_nonexistent.len == 0, "Missing Nimble files: Broken Packages."

    else:
      info "Compile with SSL to do checking of Repo URLs On-Line: '-d:ssl'."
