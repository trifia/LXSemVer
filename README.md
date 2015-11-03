# LXSemVer

`LXSemVer` aims to provide a simple yet specification compliant implementation of [Semantic Versioning 2.0.0](http://semver.org/) in Swift 2.x.

## Features

- Parsing version string into `Version` instances.
- `DotSeparatedValues` (DSV) class to represent prerelease and/or build metadata.
- `DotSeparatedValues` and `Version` instances support `next()`, which provides a list of logical next DSVs and/or versions.
- `DotSeparatedValues` and `Version` instances can be compared.

## Purposes

`LXSemVer` unique point is its concept of version graph. Semantic Versioning 2.0.0 [comparison rule]() allow for logical digraph of versioning.

![Version Graph](images/version-graph.png)

At any specific version, there are multiple logical paths leading to the next versions and these versions have logical ordering as well.

`LXSemVer` extends on Semantic Versioning 2.0.0 by recognizing `alpha`, `beta` and `rc` as the first prerelease identifiers.

Together, they make `LXSemVer` an excellent choice for versioning management. 
