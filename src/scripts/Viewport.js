import React from 'react'
import {Treebeard} from 'react-treebeard'
import NodeViewer from './NodeViewer'
import GroupViewer from './GroupViewer'
import Style from './Theme.js'
import NavBar from './NavBar'

export default class Viewport extends React.Component {
    constructor() {
        super()
        this.onToggle = this.onToggle.bind(this)
        this.onSelect = this.onSelect.bind(this)
        this.onSearch = this.onSearch.bind(this)

        this.state = {
            tree: {},
            entry: null,
            group: null,
            groupName: null,
        }
    }

    onToggle(group, toggled) {
        if (this.state.cursor) { this.state.cursor.active = false }
        group.active = true

        var cur = this.state.cursor
        this.setState({
            cursor: group
        })

        if (group.children) {
            group.toggled = toggled
        }

        if (cur == group) return

        this.setState({
            groupName: group.name,
            group: null,
            entry: null,
        })

        this.serverRequest = KeePass4Web.ajax('get_group', {
            data: {
                id: group.id,
            },
            success: function (data) {
                this.setState({
                    group: data.data,
                })
            }.bind(this),
            error: KeePass4Web.error.bind(this),
        })
    }

    onSelect(entry) {
        // ignore already selected
        if (this.state.entry && this.state.entry.id && entry.id === this.state.entry.id) return

        // remove entry first to rerender entry
        // important for eye close/open buttons
        this.setState({
            entry: null
        })
        this.serverRequest = KeePass4Web.ajax('get_entry', {
            data: {
                id: entry.id,
            },
            success: function (data) {

                this.setState({
                    entry: data.data
                })
            }.bind(this),
            error: KeePass4Web.error.bind(this),
        })
    }

    onSearch(refs, event) {
        event.preventDefault()
        this.serverRequest = KeePass4Web.ajax('search_entries', {
            data: {
                term: refs.term.value,
            },
            success: function (data) {
                if (this.state.cursor)
                    this.state.cursor.active = false
                this.setState({
                    cursor: null,
                    group: data.data,
                    groupName: 'Search results for "' + refs.term.value + '"',
                    entry: null
                })
            }.bind(this),
            error: KeePass4Web.error.bind(this),
        })
    }


    componentDidMount() {
        if (KeePass4Web.getCN()) {
            document.getElementById('logout').addEventListener('click', this.onLogout)
            document.getElementById('closeDB').addEventListener('click', this.onCloseDB)
        }
        this.serverRequest = KeePass4Web.ajax('get_tree', {
            success: function (data) {
                this.setState({
                    tree: data.data
                })
            }.bind(this),
            error: KeePass4Web.error.bind(this)
        })
    }

    componentWillUnmount() {
        if (this.serverRequest)
            this.serverRequest.abort()
    }

    render() {
        return (
            <div className="container-fluid">
                <NavBar
                    showSearch
                    onSearch={this.onSearch}
                    router={this.props.router}
                />
                <div className="row">
                    <div className="col-sm-2 dir-tree">
                        <Treebeard
                            data={this.state.tree}
                            onToggle={this.onToggle}
                            style={Style}
                        />
                    </div>
                    <div className="col-sm-4">
                        <GroupViewer
                            group={this.state.group}
                            groupName={this.state.groupName}
                            onSelect={this.onSelect}
                        />
                    </div>
                    <div className="col-sm-6">
                        <NodeViewer
                            entry={this.state.entry}
                            timeoutSec={30 * 1000}
                        />
                    </div>
                </div>
            </div>
        )
    }
}


