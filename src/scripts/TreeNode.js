import React from 'react'

export default class TreeNode extends React.Component {
    constructor(props) {
        super(props)

        var node = props.node
        this.state = {
            expanded: node.hasOwnProperty('expanded') ?
                node.expanded :
                props.level < (props.options.levels || 3) ? true : false
        }
    }

    toggleExpanded(event) {
        this.setState({ expanded: !this.state.expanded })
        event.stopPropagation()
    }

    select(node, event) {
        var nodeClick = this.props.options.nodeClick
        if (nodeClick)
            nodeClick(node)
        event.stopPropagation()
    }

    render() {
        var node = this.props.node
        var options = this.props.options
        var showBorder = typeof options.showBorder === 'undefined' ?  true : options.showBorder

        var style
        if (!this.props.visible) {
            style = { 
                display: 'none' 
            }
        }
        else {
            if (!showBorder) {
                style.border = 'none'
            }
            else if (options.borderColor) {
                style.border = '1px solid ' + options.borderColor
            }
        } 

        var indents = []
        for (var i = 0; i < this.props.level - 1; i++) {
            indents.push(<span className="indent" key={i}></span>)
        }

        var expandCollapseIcon
        if (node.children) {
            if (!this.state.expanded) {
                expandCollapseIcon = (
                    <span className={options.expandIcon || 'glyphicon glyphicon-plus'}
                        onClick={this.toggleExpanded.bind(this)}>
                    </span>
                )
            }
            else {
                expandCollapseIcon = (
                    <span className={options.collapseIcon || 'glyphicon glyphicon-minus'}
                        onClick={this.toggleExpanded.bind(this)}>
                    </span>
                )
            }
        }
        else {
            expandCollapseIcon = (
                <span className={options.emptyIcon || 'glyphicon glyphicon-none'}></span>
            )
        }

        var srcurl
        if (node.custom_icon_uuid) {
            srcurl = 'img/icon/' + encodeURIComponent(node.custom_icon_uuid.replace(/\//g, '_'))
        }
        else {
            srcurl = 'img/icons/' + encodeURIComponent(node.icon || options.nodeIcon || '48') + '.png'
        }
        var nodeIcon = (
            <img src={srcurl} className="kp-icon icon" />
        )

        var children = []
        if (node.children) {
            var nodes = node.children
            for (var i in nodes) {
                children.push(
                    <TreeNode
                        node={nodes[i]}
                        level={this.props.level + 1}
                        visible={this.state.expanded && this.props.visible}
                        options={options}
                        key={nodes[i].id}
                    />
                )
            }
        }

        return (
            <div>
                <li className="list-group-item"
                    style={style}
                    onClick={this.select.bind(this, node)}
                >
                    {indents}
                    {expandCollapseIcon}
                    {nodeIcon}
                    {node.name}
                </li>
                {children}
            </div>
        )
    }
}
