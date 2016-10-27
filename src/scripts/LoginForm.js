import React from 'react'
import Classnames from 'classnames'

export default class LoginForm extends React.Component {
    constructor() {
        super()
        this.handleLogin = this.handleLogin.bind(this);
        this.logout = this.logout.bind(this);
        this.state = {
            error: false,
            mask: false
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

    classes() {
        return Classnames({
            'kp-login': true,
            'loading-mask': this.state.mask,
        });
    }

    handleLogin(event) {
        event.preventDefault()

        var success = false
        this.setState({
            error: false,
            mask: true
        })
        this.forceUpdate()
        KeePass4Web.ajax(this.url, {
            success: function(data) {
                success = true

                if (data && data.data) {
                    KeePass4Web.setCN(data.data.cn)
                    KeePass4Web.setTemplate(data.data.credentials_tpl)
                    KeePass4Web.setCSRFToken(data.data.csrf_token)
                }

                this.setState({
                    mask: false
                })
                this.props.router.replace('/')
            }.bind(this),
            data: this.transformRefs(this.refs),
            error: function(r, s, e) {
                var errmsg = s

                // error code sent by server
                if (s == 'error' && r.responseJSON) {
                    errmsg = r.responseJSON.message
                }

                this.setState({
                    error: errmsg,
                    mask: false
                })
                // even on fail this will redirect to root and check which authentication is required
                // in case some previous auth expired while the user took too much time
                this.props.router.replace('/')
            }.bind(this)
        })

    }
}
