import React from 'react'

export default class Timer extends React.Component {
    constructor(props) {
        super()
        this.state = {
            text: '',
            endTime: this.endTime(props.timeout)
        }

        this.tick = this.tick.bind(this)
    }

    componentDidMount() {
        if (this.state.endTime) {
            var time = this.calculate(this.state.endTime)
            this.setState({
                text: this.format(time),
            })
            this.tickStart()
            this.tick()
        }
    }

    componentWillUnmount() {
        this.tickEnd()
    }

    pad(str) {
        let pad = '' + str
        if (pad.length == 1)
            pad = '0' + pad
        return pad
    }

    endTime(timeout) {
        return new Date(Date.now() + new Date(1000 * timeout).getTime())
    }

    format(time) {
        return this.props.format
            .replace(/{dd}/, this.pad(time.d))
            .replace(/{hh}/, this.pad(time.h))
            .replace(/{mm}/, this.pad(time.m))
            .replace(/{ss}/, this.pad(time.s))
    }

    tick() {
        if (this.props.restart()) {
            this.setState({
                endTime: this.endTime(this.props.timeout)
            })
            this.props.restart(false)
        }

        var format = this.props.format

        if (!(/{dd}/.test(format) || /{hh}/.test(format) || /{mm}/.test(format) || /{ss}/.test(format))) {
            this.tickEnd()
            return
        }

        var time = this.calculate(this.state.endTime)

        if (!time) {
            this.props.onTimeUp()
            this.tickEnd()
            return
        }

        var parsedText = this.format(time)

        this.setState({text: parsedText})
    }

    calculate(end) {
        var theTime = end.getTime() - Date.now()
        return theTime >= 0 ? {
            d: Math.floor(theTime / (1000 * 60 * 60 * 24)),
                h: Math.floor(theTime / (1000 * 60 * 60) % 24),
                m: Math.floor(theTime / (1000 * 60) % 60),
                s: Math.floor(theTime / 1000 % 60)
        } : false
    }

    tickStart() {
        this.timer = setInterval(this.tick, 1000)
    }

    tickEnd() {
        clearInterval(this.timer)
    }

    render() {
        return (
            <span>{this.state.text}</span>
        )
    }
}
