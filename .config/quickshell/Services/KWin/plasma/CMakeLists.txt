cmake_minimum_required(VERSION 3.24)
project(bidshell_plasma LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
find_package(Qt6 REQUIRED COMPONENTS Quick Qml Widgets)
# Plasma's CMake package names these in its link interface without finding them itself
find_package(KF6Config REQUIRED)
find_package(KF6CoreAddons REQUIRED)
find_package(Plasma REQUIRED)
find_package(PlasmaQuick REQUIRED)
find_package(KF6Package REQUIRED)
qt_standard_project_setup(REQUIRES 6.8)

# The Plasma/Shell package with our CompactApplet; read from the repo, so its QML takes effect without a rebuild
set(BIDSHELL_SHELL_PACKAGE "${CMAKE_CURRENT_SOURCE_DIR}/shell")

qt_add_qml_module(bidshell_plasma
    URI Bidshell.Plasma
    VERSION 1.0
    PLUGIN_TARGET bidshell_plasma
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/Bidshell/Plasma
    SOURCES plasmoidhost.h plasmoidhost.cpp hostcorona.h hostcorona.cpp)
target_compile_definitions(bidshell_plasma PRIVATE BIDSHELL_SHELL_PACKAGE="${BIDSHELL_SHELL_PACKAGE}")
target_link_libraries(bidshell_plasma PRIVATE Qt6::Quick Qt6::Qml Qt6::Widgets Plasma::Plasma Plasma::PlasmaQuick KF6::Package)
