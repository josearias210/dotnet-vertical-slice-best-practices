# DevOps GitHub

Use this reference when the backend change touches GitHub Actions, release images, CI build policy,
or deployable artifacts for the API host and database migrator.

## Core rule

The image-producing build workflow runs only after code reaches `main`.

Prefer:

```yaml
on:
  push:
    branches:
      - main
```

This keeps deployable build artifacts tied to merged code, not to every branch push or pull request.
If the repo also needs PR validation, keep that in a separate verification workflow that does not
publish deployable release images.

## Required outputs

The GitHub Actions build workflow must publish both container images when those projects exist:

- backend or app-host image;
- database migrator image.

Treat both images as release artifacts from the same source revision. Do not produce a backend image
without the matching migrator image when the deployment model expects both.

## Versioning policy

Use one shared `image_tag` or release version for every image produced by the same build.

The deployment workflow should be able to receive a single version input and use it consistently for
all backend-stack images. In the deployment reference workflow reviewed for this skill, the deploy job
accepts one `image_tag` input and forwards that value as `IMAGE_TAG` for the full stack deployment.
Mirror that intent in build workflows: calculate or select one tag once, then apply it to both backend
and migrator images.

Recommended behavior:

1. Determine one canonical image tag for the workflow run.
2. Build the backend image with that tag.
3. Build the migrator image with that same tag.
4. Publish or expose that single tag as the version to deploy.

## Acceptable tag strategies

Use the repo's established release model, but prefer one of these stable strategies:

- explicit semantic release tag supplied by a controlled release process;
- Git tag when builds are release-driven;
- commit-derived immutable tag for automatic `main` builds when semantic releases are not yet formalized.

Avoid mixing unrelated version values across backend and migrator images in the same workflow run.
Avoid relying on `latest` as the only deployment selector.

## Workflow expectations

Review the workflow for these conditions:

- trigger is limited to `main` for deployable build artifacts;
- workflow has permissions required to read contents and publish container images;
- backend and migrator images are both built and published;
- one shared version/tag is reused across all emitted images;
- downstream deployment can consume exactly one version value;
- the workflow naming makes the distinction between build/publish and deploy clear.

## Red flags

- publishing release images from pull request events;
- one image tagged with a release version while the paired image uses a different tag;
- deployment requiring two manual tag inputs for artifacts built from the same commit;
- backend image published without the migrator image even though migrations are part of the deployment path;
- using `latest` as the only meaningful version for production deployment.
