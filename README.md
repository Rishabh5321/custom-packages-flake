## This is just a template repo for creating a flake with all my workflows already setup


#### Secrets Needed to setup workflows


#### `flake_check`: `flake_check.yml`

- `CACHIX_AUTH_TOKEN`: For creating and setting up cachix.

#### `flake_deadnix`: `flake_deadnix.yml`

- #### No Secrets Needed

#### `flake_format`: `flake_format.yml`

- `REPO_ACCESS_TOKEN`: Github Token needed for creating pull request.

#### `update-flakes`: `update-flakes.yaml`

For creating pull request with flakebuilderapp [bot].

- `APP_ID`: Settings > Developer Settings > APP (EDIT)

- `APP_PRIVATE_KEY`: Private Key

#### `Gitlab-Sync`: `sync-to-gitlab.yml`

- `GITLAB_URL`: Gitlab Repo URL

- `USERNAME`: Username

- `GITLAB_PAT`: Gitlab Secret Token
