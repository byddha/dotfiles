#include "hostcorona.h"

#include <QFile>
#include <QGuiApplication>
#include <QStandardPaths>
#include <QHash>
#include <QScreen>

#include <KPackage/PackageLoader>
#include <Plasma/Containment>
#include <Plasma/PluginLoader>

HostCorona *HostCorona::instance()
{
    static HostCorona *corona = new HostCorona;
    return corona;
}

HostCorona::HostCorona()
{
    KPackage::Package package = KPackage::PackageLoader::self()->loadPackage(QStringLiteral("Plasma/Shell"));
    package.setPath(QStringLiteral(BIDSHELL_SHELL_PACKAGE));
    setKPackage(package);
    // The layout is the shell's config, not Plasma's, so it starts empty each session and stays out of ~/.config
    const QString layout = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) + QStringLiteral("/bidshell-plasma-appletsrc");
    QFile::remove(layout);
    loadLayout(layout);
    m_containment = createContainment(QStringLiteral("empty"));
}

QRect HostCorona::screenGeometry(int id) const
{
    const auto screens = QGuiApplication::screens();
    return id >= 0 && id < screens.size() ? screens[id]->geometry() : QRect();
}

Plasma::Applet *HostCorona::addApplet(const QString &pluginId)
{
    return m_containment->createApplet(pluginId);
}

void HostCorona::setEdge(const QString &edge)
{
    static const QHash<QString, Plasma::Types::Location> locations{{QStringLiteral("top"), Plasma::Types::TopEdge},
                                                                   {QStringLiteral("bottom"), Plasma::Types::BottomEdge},
                                                                   {QStringLiteral("left"), Plasma::Types::LeftEdge},
                                                                   {QStringLiteral("right"), Plasma::Types::RightEdge}};
    const auto location = locations.value(edge, Plasma::Types::TopEdge);
    m_containment->setLocation(location);
    m_containment->setFormFactor(location == Plasma::Types::LeftEdge || location == Plasma::Types::RightEdge ? Plasma::Types::Vertical
                                                                                                             : Plasma::Types::Horizontal);
}
