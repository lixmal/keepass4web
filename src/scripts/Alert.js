import React from 'react'

export default class Alert extends React.Component {
    constructor() {
        super()
    }

    render() {
        return this.props.error ? (
            <div className="alert alert-danger alert-dismissible login-error">
                <span className="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                <span className="sr-only">Error:</span> {this.props.error}
            </div>
        ) : null
    }
}
