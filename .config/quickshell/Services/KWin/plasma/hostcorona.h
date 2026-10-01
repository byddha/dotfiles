#pragma once

#include <Plasma/Corona>

namespace Plasma
{
class Applet;
class Containment;
}

// The Corona every PlasmoidHost in the process shares: one containment with the applets, laid out as a panel
class HostCorona : public Plasma::Corona
{
    Q_OBJECT

public:
    static HostCorona *instance();

    QRect screenGeometry(int id) const override;
    Plasma::Applet *addApplet(const QString &pluginId);
    // The bar's edge: where applets open from, and whether they lay out in a row or a column
    void setEdge(const QString &edge);

private:
    HostCorona();

    Plasma::Containment *m_containment = nullptr;
};
