import React, { Component } from 'react';
import { Grid, Header } from "semantic-ui-react"

import './App.css';
import socket from "./phoenix"


const { Row, Column } = Grid

class App extends Component {
  render() {
    return (
      <Grid container >
        <Row centered columns={1}>
          <Column textAlign="centered">
            <Header as="h1" content="Reflow Controller" />
          </Column>
        </Row>
      </Grid>
    );
  }
}

export default App;
