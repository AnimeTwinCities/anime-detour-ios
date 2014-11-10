# FLCLFilmstripsCollectionLayout

Collection view layout that shows each section in a film strip, i.e. a horizontally scrolling list.
Supports vertical scrolling only. Otherwise similar to a UICollectionViewFlowLayout layout.

## Usage

1. Include the whole Xcode project as a dependency in the project, or build `FLCLFilmstripsCollectionLayout.framework` and copy into the other project. 
2. If including the whole project as a dependency, add `FLCLFilmstripsCollectionLayout.framework` to the `Target Dependencies` build phase in the including project's target.
3. Add `FLCLFilmstripsCollectionLayout.framework` to the `Link Binary with Libraries` phase of the project.
4. If the project does not use other third-party frameworks, create a new `Copy Files` phase, change the destination to `Frameworks`, (optionally) rename the phase to `Copy Frameworks`, and add `FLCLFilmstripsCollectionLayout.framework` to be copied.
5. Import the framework (`@import FLCLFilmstripsCollectionLayout` in Swift; add a semi-colon `;` to the import statement for Objective-C) and use the `FilmstripsCollectionLayout` class. To use the class in Interface Builder, refer to it using the name `FLCLFilmstripsCollectionLayout`.

The name specified in an `@objc("name")` annotation on a Swift class does not at this time change the name of the class as seen by the Objective-C compiler, but does change the name that must be used in IB.

## License

The MIT License. See the `LICENSE` file.