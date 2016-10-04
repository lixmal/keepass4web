import React from 'react'
import Clipboard from 'clipboard-js'

export default class NodeViewer extends React.Component {
    constructor(props) {
        super(props)
        this.setHide = this.setHide.bind(this)
    }

    setHide(target, hide, name, data) {
        if (typeof data === 'undefined')
            data = null
        if (!name || name === 'password')
            this.props.entry.password = data
        else
            this.props.entry.strings[name] = data

        if (hide === true)
            target.childNodes[0].className = 'glyphicon glyphicon-eye-open'
        else
            target.childNodes[0].className = 'glyphicon glyphicon-eye-close'

        this.forceUpdate()
    }

    PWHandler(name, event) {
        var target = event.currentTarget
        if (target.childNodes[0].className == 'glyphicon glyphicon-eye-close') {
            this.setHide(target, true, name)
            return
        }

        // else true:
        event.persist()
        this.serverRequest = KeePass4Web.ajax('get_password', {
            data: {
                id: this.props.entry.id,
                name: name
            },
            success: function (data) {
                this.setHide(target, false, name, data.data)

                // hide password after X seconds
                setTimeout(this.PWTimeout.bind(this, target, name), this.props.timeoutSec)
            }.bind(this),
            error: KeePass4Web.error.bind(this),
        })

    }

    copyHandler(name, event) {
        var target = event.currentTarget.previousSibling

        this.serverRequest = KeePass4Web.ajax('get_password', {
            data: {
                id: this.props.entry.id,
                name: name
            },
            // need same thread here, else copy won't work by browser restrictions
            async: false,
            success: function (data) {
                Clipboard.copy(data.data)
            }.bind(this),
            error: KeePass4Web.error.bind(this),
        })
        this.setHide(target, true, name)
    }

    downloadHandler(filename, event) {
        // alternative:
        // window.location = 'get_file?id=' + encodeURIComponent(btoa(this.props.entry.id)) + '&filename=' + encodeURIComponent(filename)

        // mostly taken from http://stackoverflow.com/questions/16086162/handle-file-download-from-ajax-post
        // with adjustments
        var xhr = new XMLHttpRequest()
        xhr.open('POST', 'get_file', true)
        xhr.responseType = 'arraybuffer'
        xhr.onload = function () {
            if (this.status === 200) {
                var filename = ""
                var disposition = xhr.getResponseHeader('Content-Disposition')
                if (disposition && disposition.indexOf('attachment') !== -1) {
                    var filenameRegex = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/
                    var matches = filenameRegex.exec(disposition)
                    if (matches != null && matches[1]) {
                        filename = decodeURIComponent(matches[1].replace(/['"]/g, '').replace(/^UTF-8/i, ''))
                    }
                }
                var type = xhr.getResponseHeader('Content-Type')

                var blob = new Blob([this.response], { type: type })
                if (typeof window.navigator.msSaveBlob !== 'undefined') {
                    window.navigator.msSaveBlob(blob, filename)
                } else {
                    var URL = window.URL || window.webkitURL
                    var downloadUrl = URL.createObjectURL(blob)

                    if (filename) {
                        var a = document.createElement("a")
                        if (typeof a.download === 'undefined') {
                            window.location = downloadUrl
                        } else {
                            a.href = downloadUrl
                            a.download = filename
                            document.body.appendChild(a)
                            a.click()
                        }
                    } else {
                        window.location = downloadUrl
                    }

                    setTimeout(function () { URL.revokeObjectURL(downloadUrl) }, 100)
                }
            }
            else if (this.status >= 400) {
                KeePass4Web.error(xhr, null, xhr.responseText)
            }
        }
        xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
        xhr.send('id=' + encodeURIComponent(this.props.entry.id) + '&filename=' + encodeURIComponent(filename))
    }

    PWTimeout(target, name) {
        // ignore hidden passwords
        if (target.textContent === true) return
        this.setHide(target, true, name)
    }

    componentWillUnmount() {
        if (this.serverRequest)
            this.serverRequest.abort()
    }

    render() {
        if (!this.props || !this.props.entry) return null

        var entry = this.props.entry

        var fields = []
        var strings = entry.strings
        if (strings) {
            fields.push(
                <tr key="fields-header">
                    <th className="kp-fields" colSpan="3">Fields</th>
                </tr>
            )
        }
        for (var string in strings) {
            if (strings.hasOwnProperty(string)) {
                fields.push(
                    <tr key={string}>
                        <td>{string}</td>
                        <td>
                            {
                                entry.protected && entry.protected[string] ?
                                strings[string] !== null ?
                                strings[string]
                                : '******'
                                : strings[string]
                            }
                        </td>
                        { entry.protected && entry.protected[string] ?
                            <td>
                                <div className="btn-group" role="group">
                                    <button
                                        onClick={this.PWHandler.bind(this, string)}
                                        type="button"
                                        className="btn btn-default"
                                    >
                                        <span className="glyphicon glyphicon-eye-open"></span>
                                    </button>
                                    <button
                                        onClick={this.copyHandler.bind(this, string)}
                                        type="button"
                                        className="btn btn-default"
                                    >
                                        <span className="glyphicon glyphicon-copy"></span>
                                    </button>
                                </div>
                            </td>
                        : <td></td> }
                    </tr>
                )
            }
        }

        var files = []
        var binary = entry.binary
        if (binary) {
            files.push(
                <tr key="files-header">
                    <th className="kp-files" colSpan="3">Files</th>
                </tr>
            )
        }
        for (var file in binary) {
            if (binary.hasOwnProperty(file)) {
                files.push(
                    <tr key={file}>
                        <td colSpan="2">
                            {file}
                        </td>
                        <td>
                            <div className="btn-group" role="group">
                                <button
                                    onClick={this.downloadHandler.bind(this, file)}
                                    type="button"
                                    className="btn btn-default"
                                >
                                    <span className="glyphicon glyphicon-download-alt"></span>
                                </button>
                            </div>
                        </td>
                    </tr>
                )
            }
        }


        return (
            <div className="panel panel-default">
                <div className="panel-heading">
                    {entry.title}
                </div>
                <table className="table table-hover table-bordered table-sm">
                    <colgroup>
                        <col className="kp-entry-label" />
                        <col className="kp-entry-value" />
                        <col className="kp-entry-buttons" />
                    </colgroup>
                    <tbody>
                        <tr>
                            <td>
                                Username
                            </td>
                            <td>
                                {entry.username}
                            </td>
                            <td>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Password
                            </td>
                            <td>
                                { entry.password !== null ? entry.password : '******' }
                            </td>
                            <td>
                                <div className="btn-group" role="group">
                                    <button
                                        onClick={this.PWHandler.bind(this, 'password')}
                                        type="button"
                                        className="btn btn-default"
                                    >
                                        <span className="glyphicon glyphicon-eye-open"></span>
                                    </button>
                                    <button
                                        onClick={this.copyHandler.bind(this, 'password')}
                                        type="button"
                                        className="btn btn-default"
                                    >
                                        <span className="glyphicon glyphicon-copy"></span>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                URL
                            </td>
                            <td>
                                <a href={entry.url} target="_blank">{entry.url}</a>
                            </td>
                            <td>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Comments
                            </td>
                            <td className="td-entry-comment">
                                {entry.comment}
                            </td>
                            <td>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                Tags
                            </td>
                            <td>
                                {entry.tags.split(';').join(' ')}
                            </td>
                            <td>
                            </td>
                        </tr>
                        {fields}
                        {files}
                    </tbody>
                </table>
            </div>
        )
    }
}

