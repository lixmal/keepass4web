import React from 'react'
import LoginForm from './LoginForm'
import NavBar from './NavBar'
import Alert from './Alert'
import Info from './Info'
import Classnames from 'classnames'

export default class UserLogin extends LoginForm {
    constructor() {
        super()
        this.url = 'user_login'
    }

    render() {
        return (
            <div>
                <NavBar router={this.props.router} />
                <div className="container">
                    <div className={this.classes()}>
                        <form className="kp-login-inner" onSubmit={this.handleLogin}>
                            <h4>User Login</h4>
                            <input className="form-control user" autoComplete="on" type="text" ref="username" placeholder="Username" required="required" autoFocus={this.state.error ? '' : 'autoFocus'}/>
                            <input className="form-control password" type="password" ref="password" placeholder="Password" required="required" autoFocus={this.state.error ? 'autoFocus': ''} />
                            <button className="btn btn-block btn-lg btn-success" type="submit">Login</button>
                            <Alert error={this.state.error} />
                            <Info info={ this.props.location.state && this.props.location.state.info } />
                        </form>
                    </div>
                </div>
            </div>
       )
    }
}
