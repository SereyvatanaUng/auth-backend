import { IsEmail, IsNotEmpty, MinLength } from 'class-validator';

export class SignUpDto {
  @IsNotEmpty()
  username: string;

  @IsEmail()
  email: string;

  @IsNotEmpty()
  @MinLength(6)
  password: string;
}

export class LoginDto {
  @IsNotEmpty()
  username: string;

  @IsNotEmpty()
  password: string;
}
