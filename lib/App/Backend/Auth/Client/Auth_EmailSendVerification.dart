import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationDialog extends StatefulWidget {
  final User user;
  final VoidCallback? onVerified; // Callback para cuando se verifique el email

  const EmailVerificationDialog({
    Key? key,
    required this.user,
    this.onVerified,
  }) : super(key: key);

  @override
  _EmailVerificationDialogState createState() =>
      _EmailVerificationDialogState();
}

// Diálogo para mostrar la verificación de email
class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  // Variables para manejar el estado del diálogo
  // _isLoading para mostrar un indicador de carga al enviar el email
  // _emailSent para indicar si el email de verificación ha sido enviado
  // _isChecking para manejar el estado de verificación del email
  bool _isLoading = false;
  bool _emailSent = false;
  bool _isChecking = false;

  // Construye el diálogo de verificación de email
  // Incluye un título, contenido y acciones para enviar el email o verificarlo
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // Titule del diálogo
      title: const Row(
        children: [
          Icon(
            Icons.mark_email_unread,
            color: Colors.orange,
            size: 28,
          ),
          SizedBox(width: 8),
          Text(
            'Verificación de Email',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
      // Contenido del diálogo
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 48,
                  color: Colors.orange,
                ),
                SizedBox(height: 12),
                Text(
                  'Tu correo electrónico no está verificado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Necesitas verificar tu email para continuar. Te enviaremos un enlace de verificación.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (_emailSent) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Email enviado. Revisa tu bandeja de entrada y spam.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        if (!_emailSent)
          ElevatedButton(
            onPressed: _isLoading ? null : _sendVerificationEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Enviar Email'),
          ),
        if (_emailSent)
          ElevatedButton(
            onPressed: _isChecking ? null : _checkEmailVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: _isChecking
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Ya Verifiqué'),
          ),
      ],
    );
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.user.sendEmailVerification();
      setState(() {
        _emailSent = true;
      });

      // Mostrar snackbar de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Email de verificación enviado'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Manejo de errores específicos
      String errorMessage = 'Error al enviar email';

      if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Demasiadas solicitudes. Espera un momento.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkEmailVerification() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Recargar el usuario para obtener el estado más reciente
      await widget.user.reload();
      User? refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        // Email verificado exitosamente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('¡Email verificado exitosamente!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Cerrar el diálogo
        Navigator.of(context).pop();

        // Ejecutar callback si existe
        if (widget.onVerified != null) {
          widget.onVerified!();
        }
      } else {
        // Email aún no verificado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Email aún no verificado. Revisa tu bandeja de entrada.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Error al verificar el estado'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }
}

// Función helper para mostrar el diálogo fácilmente
void showEmailVerificationDialog(BuildContext context, User user,
    {VoidCallback? onVerified}) {
  showDialog(
    context: context,
    barrierDismissible: false, // No se puede cerrar tocando fuera
    builder: (BuildContext context) {
      return EmailVerificationDialog(
        user: user,
        onVerified: onVerified,
      );
    },
  );
}
