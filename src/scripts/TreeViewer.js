import React from 'react'
import TreeNode from './TreeNode'

export default class TreeViewer extends React.Component {
    render() {
        var root = this.props.tree || {}
        var tree = root.children

        var children = []
        for (var i in tree) {
            children.push(
                <TreeNode
                    node={tree[i]}
                    level={1}
                    visible={true}
                    options={this.props}
                    key={tree[i].id}
                />
            )
        }

        var srcurl
        if (root.custom_icon_uuid) {
            srcurl = 'img/icon/' + root.custom_icon_uuid.replace(/\//g, '_')
        }
        else {
            srcurl = 'img/icons/' + (root.icon || this.props.nodeIcon || '0') + '.png'
        }
        var nodeIcon = (
            <img src={srcurl} className="kp-icon icon" />
        )

        return (
            <div className="panel panel-default">
                <div className="panel-heading">
                    {nodeIcon}
                    {root.name}
                </div>

                <ul className='treeview list-group'>
                    {children}
                </ul>
            </div>
        )
    }
}


