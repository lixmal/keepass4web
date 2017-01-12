import React from 'react'

export default class Alert extends React.Component {
    constructor() {
        super()
    }

    render() {
        return this.props.info? (
            <div className="alert alert-info alert-dismissible login-error">
                <span className="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                <span className="sr-only">Info:</span> {this.props.info}
            </div>
        ) : null
    }
}
