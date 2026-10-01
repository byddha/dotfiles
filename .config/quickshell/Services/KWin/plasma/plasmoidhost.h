#pragma once

#include <QPointer>
#include <QQuickItem>
#include <QtQml/qqmlregistration.h>

namespace Plasma
{
class Applet;
}
namespace PlasmaQuick
{
class AppletQuickItem;
}

// A Plasma applet hosted in this item: its compact representation fills it, and its full representation is
// handed out as fullRepresentation for the shell to place in a popup of its own
class PlasmoidHost : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString applet READ applet WRITE setApplet NOTIFY appletChanged)
    Q_PROPERTY(QString edge READ edge WRITE setEdge NOTIFY edgeChanged)
    Q_PROPERTY(bool expanded READ expanded WRITE setExpanded NOTIFY expandedChanged)
    Q_PROPERTY(QQuickItem *fullRepresentation READ fullRepresentation NOTIFY fullRepresentationChanged)
    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString toolTipMainText READ toolTipMainText NOTIFY toolTipChanged)
    Q_PROPERTY(QString toolTipSubText READ toolTipSubText NOTIFY toolTipChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit PlasmoidHost(QQuickItem *parent = nullptr);
    ~PlasmoidHost() override;

    QString applet() const;
    void setApplet(const QString &applet);
    QString edge() const;
    void setEdge(const QString &edge);
    bool expanded() const;
    void setExpanded(bool expanded);
    QQuickItem *fullRepresentation() const;
    QString title() const;
    QString toolTipMainText() const;
    QString toolTipSubText() const;
    QString error() const;

Q_SIGNALS:
    void appletChanged();
    void edgeChanged();
    void expandedChanged();
    void fullRepresentationChanged();
    void titleChanged();
    void toolTipChanged();
    void errorChanged();

protected:
    void componentComplete() override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    void load();
    void fit();
    void fail(const QString &error);

    QString m_pluginId;
    QString m_edge = QStringLiteral("top");
    QString m_error;
    QPointer<Plasma::Applet> m_applet;
    QPointer<PlasmaQuick::AppletQuickItem> m_item;
};
