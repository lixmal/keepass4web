import React from 'react'

export default class GroupViewer extends React.Component {
    constructor(props) {
        super(props)
    }

    render() {
        if (!this.props || !this.props.group) return (<div></div>)

        var group = this.props.group


        var entries = []
        for (var i in group) {
            let entry = group[i]
            entries.push(
                <tr key={i} onClick={this.props.onSelect.bind(this, entry)}>
                    <td>
                        {entry.title}
                    </td>
                    <td>
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
                <table className="table table-hover table-bordered table-sm">
                    <colgroup>
                        <col className="kp-group-label" />
                        <col className="kp-group-username" />
                    </colgroup>
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
        )
    }
}

