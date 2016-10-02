import React from 'react'

export default class LoginForm extends React.Component {
    constructor() {
        super()
        this.handleLogin = this.handleLogin.bind(this);
        this.logout = this.logout.bind(this);
        this.state = {
            error: false
        }
    }

    transformRefs(tRefs) {
        var refs = {}
        for (var property in tRefs) {
            if (tRefs.hasOwnProperty(property)) {
                refs[property] = tRefs[property].value
            }
        }

        return refs
    }

    logout() {
        window.KeePass4Web.logout(this.props.router);
    }

    handleLogin(event) {
        event.preventDefault()

        var success = false
        KeePass4Web.ajax(this.url, {
            success: function(data) {
                this.setState({ error: false })
                success = true
            }.bind(this),
            async: false,
            data: this.transformRefs(this.refs),
            error: function(r, s, e) {
                var errmsg = s

                // error code sent by server
                if (s == 'error' && r.responseJSON) {
                    errmsg = r.responseJSON.message
                }
                this.setState({ error: errmsg })
            }.bind(this)
        })

        // even on fail this will redirect to root and check which authentication is required
        // in case some previous auth expired while the user took too much time
        const { location } = this.props
        if (location.state && location.state.nextPathname) {
            this.props.router.replace(location.state.nextPathname)
        } else {
            this.props.router.replace('/')
        }
    }
}
