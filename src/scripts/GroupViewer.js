import React from 'react'

export default class GroupViewer extends React.Component {
    constructor(props) {
        super(props)
    }

    getIcon(element) {
        var icon = null
        if (element.custom_icon_uuid)
            icon = <img className="kp-icon" src={'img/icon/' + encodeURIComponent(element.custom_icon_uuid.replace(/\//g, '_'))} />
        else if (element.icon)
            icon = <img className="kp-icon" src={'img/icons/' + encodeURIComponent(element.icon) + '.png'} />

        return icon
    }

    render() {
        if (!this.props || !this.props.group) return null

        var group = this.props.group

        var entries = []
        for (var i in group.entries) {
            let entry = group.entries[i]

            entries.push(
                <tr key={i} onClick={this.props.onSelect.bind(this, entry)}>
                    <td className="kp-wrap">
                        {this.getIcon(entry)}
                        {entry.title}
                    </td>
                    <td className="kp-wrap">
                        {entry.username}
                    </td>
                </tr>
            )
        }

        return (
            <div className="panel panel-default">
                <div className="panel-heading">
                    {this.getIcon(group)}
                    {group.title}
                </div>
                <div className="panel-body">
                    <table className="table table-hover table-condensed kp-table">
                        <thead>
                            <tr>
                                <th>
                                    Entry Name
                                </th>
                                <th>
                                    Username
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            {entries}
                        </tbody>
                    </table>
                </div>
            </div>
        )
    }
}

