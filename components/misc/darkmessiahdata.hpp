#ifndef OPENMW_MISC_DARKMESSIAHDATA_H
#define OPENMW_MISC_DARKMESSIAHDATA_H

#include <array>
#include <charconv>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <string_view>

// Data that brutalmorrowind-import builds from the user's own Dark Messiah and
// Morrowind files. It lives in the user data directory, one folder per recipe,
// and is used only when its readiness marker names the recipe of this build.
namespace Misc::DarkMessiahData
{
    // Raise together with RECIPE_VERSION in tools/dm-import/dm_import.py.
    inline constexpr int sRecipe = 2;

    inline constexpr std::string_view sMarker = "dm-import-ready.json";

    // Lowest priority first, the order the importer's parts were tested in.
    inline constexpr std::array<std::string_view, 8> sParts{ "kick-data", "npc-data", "firstperson-data",
        "effects-data", "slide-data", "clinch-data", "body-data", "creature-data" };

    inline std::filesystem::path root(const std::filesystem::path& userData)
    {
        return userData / "dm-assets" / std::to_string(sRecipe);
    }

    // Recipe named by the marker in `folder`, or -1 when it is missing or unreadable.
    inline int markerRecipe(const std::filesystem::path& folder)
    {
        std::ifstream stream(folder / sMarker);
        if (!stream)
            return -1;
        const std::string text{ std::istreambuf_iterator<char>(stream), std::istreambuf_iterator<char>() };
        const std::size_t key = text.find("\"recipe\"");
        const std::size_t colon = key == std::string::npos ? key : text.find(':', key);
        if (colon == std::string::npos)
            return -1;
        std::size_t start = text.find_first_not_of(" \t\r\n", colon + 1);
        if (start == std::string::npos)
            return -1;
        int value = -1;
        const auto [end, error] = std::from_chars(text.data() + start, text.data() + text.size(), value);
        return error == std::errc() ? value : -1;
    }

    inline bool isReady(const std::filesystem::path& userData)
    {
        const std::filesystem::path folder = root(userData);
        if (markerRecipe(folder) != sRecipe)
            return false;
        std::error_code error;
        for (std::string_view part : sParts)
            if (!std::filesystem::is_directory(folder / part, error))
                return false;
        return true;
    }
}

#endif
