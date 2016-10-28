import React from 'react'
import LoginForm from './LoginForm'
import NavBar from './NavBar'
import Alert from './Alert'

export default class DBLogin extends LoginForm {
    constructor() {
        super()
        this.url = 'db_login'
        this.handleFile = this.handleFile.bind(this)
    }

    handleFile(event) {
        var file = event.target.files[0]
        var reader = new FileReader()

        var me = this
        reader.onload = function () {
            // race condition!?
            me.refs.key.value = reader.result
        }
        reader.readAsDataURL(file)
    }

    render() {
        return (
            <div>
                <NavBar router={this.props.router} />
                <div className="container">
                    <div className={this.classes()}>
                        <form className="kp-login-inner" onSubmit={this.handleLogin}>
                            <h4>KeePass Login</h4>
                            <input className="form-control user" type="password" ref="password" placeholder="Master Password" autoFocus="autoFocus" />
                            <input className="input-group btn" type="file" accept="*/*" ref="keyfile" placeholder="Key file" onChange={this.handleFile}/>
                            <input id="key" ref="key" type="hidden"/>
                            <button className="btn btn-block btn-lg btn-success" type="submit">Open</button>
                            <Alert error={this.state.error} />
                        </form>
                    </div>
                </div>
            </div>
        )
    }
}
