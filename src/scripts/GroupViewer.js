import React from 'react'

export default class GroupViewer extends React.Component {
    constructor(props) {
        super(props)
    }

    render() {
        if (!this.props || !this.props.group) return null

        var group = this.props.group


        var entries = []
        for (var i in group) {
            let entry = group[i]
            entries.push(
                <tr key={i} onClick={this.props.onSelect.bind(this, entry)}>
                    <td className="kp-wrap">
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
                    {this.props.groupName}
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

