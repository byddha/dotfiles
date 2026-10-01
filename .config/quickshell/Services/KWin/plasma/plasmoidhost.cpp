#include "plasmoidhost.h"
#include "hostcorona.h"

#include <Plasma/Applet>
#include <PlasmaQuick/AppletQuickItem>

#include <QMetaProperty>

PlasmoidHost::PlasmoidHost(QQuickItem *parent)
    : QQuickItem(parent)
{
}

PlasmoidHost::~PlasmoidHost()
{
    if (m_applet)
        m_applet->destroy();
}

QString PlasmoidHost::applet() const
{
    return m_pluginId;
}

void PlasmoidHost::setApplet(const QString &applet)
{
    if (m_pluginId == applet)
        return;
    m_pluginId = applet;
    Q_EMIT appletChanged();
    if (isComponentComplete())
        load();
}

QString PlasmoidHost::edge() const
{
    return m_edge;
}

void PlasmoidHost::setEdge(const QString &edge)
{
    if (m_edge == edge)
        return;
    m_edge = edge;
    HostCorona::instance()->setEdge(edge);
    Q_EMIT edgeChanged();
}

bool PlasmoidHost::expanded() const
{
    return m_item && m_item->isExpanded();
}

void PlasmoidHost::setExpanded(bool expanded)
{
    if (m_item)
        m_item->setExpanded(expanded);
}

QQuickItem *PlasmoidHost::fullRepresentation() const
{
    return m_item ? m_item->fullRepresentationItem() : nullptr;
}

QString PlasmoidHost::title() const
{
    return m_applet ? m_applet->title() : QString();
}

// PlasmoidItem, the applet's root, is not public API; its tooltip texts are read as properties
QString PlasmoidHost::toolTipMainText() const
{
    return m_item ? m_item->property("toolTipMainText").toString() : QString();
}

QString PlasmoidHost::toolTipSubText() const
{
    return m_item ? m_item->property("toolTipSubText").toString() : QString();
}

QString PlasmoidHost::error() const
{
    return m_error;
}

void PlasmoidHost::componentComplete()
{
    QQuickItem::componentComplete();
    load();
}

void PlasmoidHost::load()
{
    if (m_pluginId.isEmpty() || m_applet)
        return;
    HostCorona::instance()->setEdge(m_edge);
    m_applet = HostCorona::instance()->addApplet(m_pluginId);
    if (!m_applet) {
        fail(QStringLiteral("no applet named %1 is installed").arg(m_pluginId));
        return;
    }
    if (m_applet->failedToLaunch()) {
        fail(m_applet->launchErrorMessage());
        return;
    }
    m_item = PlasmaQuick::AppletQuickItem::itemForApplet(m_applet);
    if (!m_item) {
        fail(QStringLiteral("its QML did not load"));
        return;
    }
    for (const char *name : {"toolTipMainText", "toolTipSubText"}) {
        const QMetaProperty property = m_item->metaObject()->property(m_item->metaObject()->indexOfProperty(name));
        if (property.hasNotifySignal())
            connect(m_item, property.notifySignal(), this, metaObject()->method(metaObject()->indexOfSignal("toolTipChanged()")));
    }
    m_item->setParentItem(this);
    m_item->setVisible(true);
    fit();
    connect(m_item, &PlasmaQuick::AppletQuickItem::expandedChanged, this, &PlasmoidHost::expandedChanged);
    connect(m_item, &PlasmaQuick::AppletQuickItem::fullRepresentationItemChanged, this, &PlasmoidHost::fullRepresentationChanged);
    connect(m_applet, &Plasma::Applet::titleChanged, this, &PlasmoidHost::titleChanged);
    Q_EMIT titleChanged();
    Q_EMIT toolTipChanged();
    Q_EMIT fullRepresentationChanged();
}

void PlasmoidHost::fail(const QString &error)
{
    if (m_applet)
        m_applet->destroy();
    m_error = error;
    Q_EMIT errorChanged();
}

void PlasmoidHost::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    fit();
}

void PlasmoidHost::fit()
{
    if (!m_item)
        return;
    m_item->setPosition(QPointF(0, 0));
    m_item->setSize(size());
}
