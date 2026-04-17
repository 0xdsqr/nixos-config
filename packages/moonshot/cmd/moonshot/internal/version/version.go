package version

// Value holds the version string.
//
// Default during development is "dev"
// but the build system replaces it with
// a Git version when building releases.
var Value = "dev"

// Get returns the current version string
func Get() string {
	return Value
}
