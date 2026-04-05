use nostr::Event;
use serde_json::Value;

#[derive(Debug)]
pub enum ProtocolError {
    Json(serde_json::Error),
    UnexpectedMessage(String),
}

impl core::fmt::Display for ProtocolError {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            ProtocolError::Json(e) => write!(f, "JSON error: {e}"),
            ProtocolError::UnexpectedMessage(s) => write!(f, "unexpected relay message: {s}"),
        }
    }
}

impl From<serde_json::Error> for ProtocolError {
    fn from(e: serde_json::Error) -> Self {
        ProtocolError::Json(e)
    }
}

#[derive(Debug, Clone)]
pub enum RelayMessage {
    Event { subscription_id: String, event: Box<Event> },
    Ok(OkResponse),
    Eose { subscription_id: String },
    Closed { subscription_id: String, message: String },
    Notice { message: String },
    Auth { challenge: String },
}

#[derive(Debug, Clone)]
pub struct OkResponse {
    pub event_id: String,
    pub accepted: bool,
    pub message: String,
}

pub fn parse_relay_message(text: &str) -> Result<RelayMessage, ProtocolError> {
    let arr: Vec<Value> = serde_json::from_str(text)?;
    let msg_type = arr
        .first()
        .and_then(|v| v.as_str())
        .ok_or_else(|| ProtocolError::UnexpectedMessage(text.to_string()))?;
    match msg_type {
        "EVENT" => {
            let sub_id = arr
                .get(1)
                .and_then(|v| v.as_str())
                .ok_or_else(|| ProtocolError::UnexpectedMessage(text.to_string()))?
                .to_string();
            let event: Event = serde_json::from_value(
                arr.get(2)
                    .cloned()
                    .ok_or_else(|| ProtocolError::UnexpectedMessage(text.to_string()))?,
            )?;
            Ok(RelayMessage::Event { subscription_id: sub_id, event: Box::new(event) })
        }
        "OK" => {
            let event_id = arr
                .get(1)
                .and_then(|v| v.as_str())
                .ok_or_else(|| ProtocolError::UnexpectedMessage(text.to_string()))?
                .to_string();
            let accepted = arr.get(2).and_then(|v| v.as_bool()).unwrap_or(false);
            let message = arr.get(3).and_then(|v| v.as_str()).unwrap_or("").to_string();
            Ok(RelayMessage::Ok(OkResponse { event_id, accepted, message }))
        }
        "EOSE" => {
            let sub_id = arr
                .get(1)
                .and_then(|v| v.as_str())
                .ok_or_else(|| ProtocolError::UnexpectedMessage(text.to_string()))?
                .to_string();
            Ok(RelayMessage::Eose { subscription_id: sub_id })
        }
        "CLOSED" => {
            let sub_id = arr
                .get(1)
                .and_then(|v| v.as_str())
                .ok_or_else(|| ProtocolError::UnexpectedMessage(text.to_string()))?
                .to_string();
            let message = arr.get(2).and_then(|v| v.as_str()).unwrap_or("").to_string();
            Ok(RelayMessage::Closed { subscription_id: sub_id, message })
        }
        "NOTICE" => {
            let message = arr.get(1).and_then(|v| v.as_str()).unwrap_or("").to_string();
            Ok(RelayMessage::Notice { message })
        }
        "AUTH" => {
            let challenge = arr
                .get(1)
                .and_then(|v| v.as_str())
                .ok_or_else(|| ProtocolError::UnexpectedMessage(text.to_string()))?
                .to_string();
            Ok(RelayMessage::Auth { challenge })
        }
        other => Err(ProtocolError::UnexpectedMessage(format!("unknown message type: {other}"))),
    }
}
