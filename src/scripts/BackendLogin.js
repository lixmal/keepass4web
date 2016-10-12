import React from 'react'
import LoginForm from './LoginForm'
import NavBar from './NavBar'
import Alert from './Alert'

export default class BackendLogin extends LoginForm {
    constructor() {
        super()
        this.url = 'backend_login'
    }

    render() {

        var tpl = KeePass4Web.getTemplate()

        if (!tpl)
            return null

        var fields = []
        for (var i in tpl.fields) {
            let field = tpl.fields[i]
            fields.push(
                <input
                    key={field.field}
                    className={ 'form-control ' + (field.type === 'password' ? 'password' : 'user') }
                    type={field.type}
                    ref={field.field}
                    placeholder={field.placeholder}
                    required={ field.required ? 'required' : '' }
                    autoFocus={ field.autofocus ? 'autoFocus' : '' }
                />
            )
        }

        return (
            <div>
                <NavBar router={this.props.router} />
                <div className="container">
                    <div className="kp-login">
                        <form className="kp-login-inner" onSubmit={this.handleLogin}>
                            <h4>{tpl.icon_src ? <img className="backend-icon" src={tpl.icon_src} /> : ''}{tpl.login_title}</h4>
                            {fields}
                            <button className="btn btn-block btn-lg btn-success" type="submit">Login</button>
                            <Alert error={this.state.error} key={Math.random(Math.pow(2, 32))}/>
                        </form>
                    </div>
                </div>
            </div>
        )
    }
}
