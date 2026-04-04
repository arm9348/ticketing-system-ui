from flask import Flask, redirect, render_template, request, url_for

from services.helpdesk_service import (
    add_ticket_comment,
    create_ticket,
    delete_ticket,
    get_filter_options,
    get_report_data,
    get_ticket,
    get_ticket_comments,
    get_ticket_form_options,
    list_tickets,
    update_ticket,
)


app = Flask(__name__)


@app.route("/")
def index():
    return redirect(url_for("tickets_list"))


@app.route("/tickets")
def tickets_list():
    filters = {
        "status_id": request.args.get("status_id", type=int),
        "category_id": request.args.get("category_id", type=int),
        "assignee_id": request.args.get("assignee_id", type=int),
    }
    tickets = list_tickets(filters)
    filter_options = get_filter_options()
    return render_template(
        "tickets_list.html",
        tickets=tickets,
        filters=filters,
        filter_options=filter_options,
    )


@app.route("/tickets/new")
def tickets_new():
    return render_template(
        "ticket_form.html",
        ticket=None,
        form_action=url_for("tickets_create"),
        form_title="Create Ticket",
        options=get_ticket_form_options(),
        errors=[],
        submitted={},
    )


@app.route("/tickets", methods=["POST"])
def tickets_create():
    form_data = request.form.to_dict()
    errors, ticket_id = create_ticket(form_data)
    if errors:
        return render_template(
            "ticket_form.html",
            ticket=None,
            form_action=url_for("tickets_create"),
            form_title="Create Ticket",
            options=get_ticket_form_options(),
            errors=errors,
            submitted=form_data,
        ), 400
    return redirect(url_for("ticket_detail", ticket_id=ticket_id))


@app.route("/tickets/<int:ticket_id>")
def ticket_detail(ticket_id):
    ticket = get_ticket(ticket_id)
    if not ticket:
        return render_template("not_found.html", item_name="Ticket"), 404

    comments = get_ticket_comments(ticket_id)
    return render_template(
        "ticket_detail.html",
        ticket=ticket,
        comments=comments,
        options=get_ticket_form_options(),
        errors=[],
    )


@app.route("/tickets/<int:ticket_id>/edit")
def ticket_edit(ticket_id):
    ticket = get_ticket(ticket_id)
    if not ticket:
        return render_template("not_found.html", item_name="Ticket"), 404

    return render_template(
        "ticket_form.html",
        ticket=ticket,
        form_action=url_for("ticket_update", ticket_id=ticket_id),
        form_title=f"Edit Ticket #{ticket_id}",
        options=get_ticket_form_options(),
        errors=[],
        submitted=ticket,
    )


@app.route("/tickets/<int:ticket_id>/update", methods=["POST"])
def ticket_update(ticket_id):
    existing_ticket = get_ticket(ticket_id)
    if not existing_ticket:
        return render_template("not_found.html", item_name="Ticket"), 404

    form_data = request.form.to_dict()
    errors = update_ticket(ticket_id, form_data)
    if errors:
        merged_data = dict(existing_ticket)
        merged_data.update(form_data)
        return render_template(
            "ticket_form.html",
            ticket=existing_ticket,
            form_action=url_for("ticket_update", ticket_id=ticket_id),
            form_title=f"Edit Ticket #{ticket_id}",
            options=get_ticket_form_options(),
            errors=errors,
            submitted=merged_data,
        ), 400
    return redirect(url_for("ticket_detail", ticket_id=ticket_id))


@app.route("/tickets/<int:ticket_id>/delete", methods=["POST"])
def ticket_delete(ticket_id):
    delete_ticket(ticket_id)
    return redirect(url_for("tickets_list"))


@app.route("/tickets/<int:ticket_id>/comments", methods=["POST"])
def ticket_comment_create(ticket_id):
    ticket = get_ticket(ticket_id)
    if not ticket:
        return render_template("not_found.html", item_name="Ticket"), 404

    errors = add_ticket_comment(ticket_id, request.form.to_dict())
    if errors:
        comments = get_ticket_comments(ticket_id)
        return render_template(
            "ticket_detail.html",
            ticket=ticket,
            comments=comments,
            options=get_ticket_form_options(),
            errors=errors,
        ), 400

    return redirect(url_for("ticket_detail", ticket_id=ticket_id))


@app.route("/reports")
def reports():
    return render_template("reports.html", reports=get_report_data())


if __name__ == "__main__":
    app.run(debug=True)
