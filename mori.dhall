let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/3522f4a51181d73c9c90fc27a7c0838bd29ae95f/package.dhall
        sha256:dcb19e2312e790bad14e622cc98a1281cd2298c5b564a2f0d0534d3c718d8803

in  Schema.Project::{
    , project = Schema.ProjectIdentity::{
      , name = "seihou-kit"
      , namespace = "shinzui"
      , stableId = Some "project_01m5zfkmrae229qacqkhkcttv0"
      , type = Schema.PackageType.Other "Kit"
      , language = Schema.Language.Other "Markdown"
      , lifecycle = Schema.Lifecycle.Active
      , description = Some
          "Claude Code skills and subagents for seihou end-users, installed via seihou kit"
      , domains = [ "Developer Tooling", "Code Generation" ]
      , owners = [ "shinzui" ]
      }
    , repos =
      [ Schema.Repo::{ name = "seihou-kit", github = Some "shinzui/seihou-kit" } ]
    , dependencies = [ "shinzui/seihou" ]
    , dependencyRefs =
      [ Schema.MoriRef::{ namespace = "shinzui", name = "seihou" } ]
    , skills =
      [ Schema.Skill::{
        , name = "seihou-scaffold-kit-skill"
        , description =
            "Scaffold new Claude Code skills and agents for Seihou, following established conventions."
        , path = Some "skills/seihou-scaffold-kit-skill"
        }
      , Schema.Skill::{
        , name = "seihou-module-readme"
        , description =
            "Write or refresh a short README.md for a Seihou module, recipe, blueprint, or prompt that points to its page in the registry's generated OKF documentation bundle."
        , path = Some "skills/seihou-module-readme"
        }
      ]
    }
